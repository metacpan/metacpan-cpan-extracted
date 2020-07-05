package DBIx::TempDB::Util;
use strict;
use warnings;
use Exporter 'import';

use Carp qw(confess croak);
use IO::Select;
use POSIX;
use Scalar::Util 'blessed';
use URI::db;
use URI::QueryParam;

use constant DEBUG               => $ENV{DBIX_TEMP_DB_DEBUG}               || 0;
use constant KILL_SLEEP_INTERVAL => $ENV{DBIX_TEMP_DB_KILL_SLEEP_INTERVAL} || 2;

our @EXPORT_OK = qw(dsn_for on_process_end parse_sql);

sub dsn_for {
  my ($url, $database_name) = @_;
  $url = URI::db->new($url) unless blessed $url;
  croak "Unknown engine for $url" unless $url->has_recognized_engine;

  my $engine = $url->canonical_engine;
  $database_name //= $url->dbname;
  return _dsn_for_mysql($url, $database_name)  if $engine eq 'mysql';
  return _dsn_for_pg($url, $database_name)     if $engine eq 'pg';
  return _dsn_for_sqlite($url, $database_name) if $engine eq 'sqlite';
  croak "Can't create DSN for engine $engine.";
}

sub on_process_end {
  my $code = pop;
  my $mode = shift // 'fork';

  return _on_process_end_fork($code)        if $mode eq 'fork';
  return _on_process_end_double_fork($code) if $mode eq 'double_fork';
  return DBIx::TempDB::Guard->new($code, $$);
}

sub parse_sql {
  my ($type, $sql) = @_;
  $type = $type->canonical_engine if blessed $type;
  return _parse_mysql($sql) if $type eq 'mysql';
  return $sql;
}

sub _dsn_for_mysql {
  my ($url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};
  my ($dsn, @userinfo);

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  $dsn      = $url->dbi_dsn;
  @userinfo = ($url->user, $url->password);

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;
  $opt{mysql_enable_utf8}   //= 1;

  return $dsn, @userinfo[0, 1], \%opt;
}

sub _dsn_for_pg {
  my ($url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};
  my ($dsn, @userinfo);

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  if (my $service = delete $opt{service}) { $url->query_param(service => $service) }
  $dsn      = $url->dbi_dsn;
  @userinfo = ($url->user, $url->password);

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;

  return $dsn, @userinfo[0, 1], \%opt;
}

sub _dsn_for_sqlite {
  my ($url, $database_name) = @_;
  my %opt = %{$url->query_form_hash};

  $url = URI::db->new($url);
  $url->dbname($database_name);
  $url->query(undef);
  my $dsn = $url->dbi_dsn;

  $opt{AutoCommit}          //= 1;
  $opt{AutoInactiveDestroy} //= 1;
  $opt{PrintError}          //= 0;
  $opt{RaiseError}          //= 1;
  $opt{sqlite_unicode}      //= 1;

  return $dsn, "", "", \%opt;
}

sub _on_process_end_double_fork {
  my $code = shift;
  my $ppid = $$;

  warn "[TempDB:$$] Watching process using double fork.\n" if DEBUG;
  local $SIG{CHLD} = 'DEFAULT';
  pipe(my ($READER), my ($WRITER)) or confess "Couldn't create pipe: $!";

  # Parent
  if (my $pid_1 = fork // confess "Couldn't fork: $!") {
    my $pid_2;

    # Wait around until the second fork is done so that when we return from
    # here there are no new child processes that could mess things up if the
    # calling process does any process handling.
    close $WRITER;
    $pid_2 = <$READER>;
    $pid_2 = $pid_2 =~ m!(\d+)! ? $1 : undef;
    waitpid $pid_1, 0;
    confess "Couldn't get pid_2 from $pid_1." unless $pid_2;
    warn "[TempDB:$$] Double forked from $$ to $pid_1 to $pid_2\n" if DEBUG;
    return DBIx::TempDB::Guard->new(sub { kill TERM => $pid_2 }, $pid_2);
  }

  # Child #1
  # Detach completely from parent by creating our own session and process
  # group, closing all filehandles and forking a second time.
  $0 = "dbix-on-process-end-$ppid";
  close $READER;
  $DB::CreateTTY = 0;
  POSIX::setsid() != -1 or die "[TempDB:$$] Couldn't become session leader: $!\n";

  if (my $pid_2 = fork // die "[TempDB:$$] Couldn't fork: $!") {
    print $WRITER "$pid_2\n";
    close $WRITER;
    POSIX::_exit(0);
  }

  # Child #2
  warn "[TempDB:$ppid/$$] Double fork waiting on signals or parent to go away.\n" if DEBUG;
  _on_process_signals($code);
  sleep KILL_SLEEP_INTERVAL while kill 0, $ppid;
  local $ENV{DBIX_TEMP_DB_SIGNAL} = 'parent';
  $code->();
  exit;
}

sub _on_process_end_fork {
  my $code = shift;
  my $ppid = $$;

  # Parent
  warn "[TempDB:$$] Watching process using single fork.\n" if DEBUG;
  pipe(my ($READER), my ($WRITER)) or confess "Couldn't create pipe: $!";
  defined(my $pid = fork)          or confess "Couldn't fork: $!";
  return DBIx::TempDB::Guard->new(sub { close $WRITER }, $pid) if $pid;

  # Child
  $0             = "dbix-on-process-end-$ppid";
  $DB::CreateTTY = 0;
  close $WRITER;
  warn "[TempDB:$ppid/$$] Fork waiting on signals or pipe to go away.\n" if DEBUG;
  _on_process_signals($code);
  IO::Select->new($READER)->can_read;
  local $ENV{DBIX_TEMP_DB_SIGNAL} = 'pipe';
  $code->();
  exit;
}

sub _on_process_signals {
  my $code = shift;
  for my $name (qw(INT QUIT TERM)) {
    $SIG{$name} = sub { local $ENV{DBIX_TEMP_DB_SIGNAL} = $name; $code->(); exit; };
  }
}

sub _parse_mysql {
  my $sql = shift;
  my ($new, $last, $delimiter) = (0, '', ';');
  my @commands;

  while (length($sql) > 0) {
    my $token;

    if ($sql =~ /^$delimiter/x) {
      ($new, $token) = (1, $delimiter);
    }
    elsif ($sql =~ /^delimiter\s+(\S+)\s*(?:\n|\z)/ip) {
      ($new, $token, $delimiter) = (1, ${^MATCH}, $1);
    }
    elsif ($sql =~ /^(\s+)/s or $sql =~ /^(\w+)/) {    # general name
      $token = $1;
    }
    elsif (
      $sql    =~ /^--.*(?:\n|\z)/p                             # double-dash comment
      or $sql =~ /^\#.*(?:\n|\z)/p                             # hash comment
      or $sql =~ /^\/\*(?:[^\*]|\*[^\/])*(?:\*\/|\*\z|\z)/p    # C-style comment
      or $sql =~ /^'(?:[^'\\]*|\\(?:.|\n)|'')*(?:'|\z)/p       # single-quoted literal text
      or $sql =~ /^"(?:[^"\\]*|\\(?:.|\n)|"")*(?:"|\z)/p       # double-quoted literal text
      or $sql =~ /^`(?:[^`]*|``)*(?:`|\z)/p
      )
    {                                                          # schema-quoted literal text
      $token = ${^MATCH};
    }
    else {
      $token = substr($sql, 0, 1);
    }

    # chew token
    substr $sql, 0, length($token), '';

    if ($new) {
      push @commands, $last if $last !~ /^\s*$/s;
      ($new, $last) = (0, '');
    }
    else {
      $last .= $token;
    }
  }

  push @commands, $last if $last !~ /^\s*$/s;
  return map { s/^\s+//; $_ } @commands;
}

package DBIx::TempDB::Guard;
sub new     { my $class = shift; bless [@_], $class }
sub DESTROY { shift->[0]->() }

package DBIx::TempDB::Util;
1;

=encoding utf8

=head1 NAME

DBIx::TempDB::Util - Utility functions for DBIx::TempDB

=head1 SYNOPSIS

  use DBIx::TempDB::Util qw(dsn_for parse_sql);

  my $url = URI::db->new("postgresql://postgres@localhost");
  print join ", ", dsn_for($url);

  my $guard = on_process_end sub { ... };
  undef $guard; # call the code block earlier

  print $_ for parse_sql("mysql", "delimiter //\ncreate table y (bar varchar(255))//\n");

=head1 DESCRIPTION

L<DBIx::TempDB::Util> contains some utility functions for L<DBIx::TempDB>.

=head1 FUNCTIONS

=head2 dsn_for

  @dsn = dsn_for +URI::db->new("postgresql://postgres@localhost");
  @dsn = dsn_for "postgresql://postgres@localhost";

L</dsn_for> takes either a string or L<URI::db> object and returns a list of
arguments suitable for L<DBI/connect>.

=head2 on_process_end

  $guard = on_process_end sub { ... };
  $guard = on_process_end $mode       => sub { ... };
  $guard = on_process_end destroy     => sub { ... };
  $guard = on_process_end double_fork => sub { ... };
  $guard = on_process_end fork        => sub { ... };

Used to set up a code block to be called when the process ends. The default
C<$mode> is "fork". The C<$guard> value can be used to call the code block
before the process ends:

  undef $guard; # call sub { ... }

=over 2

=item * destroy

This mode will call the callback when the current process ends normally. This
means that if the process is killed with SIGKILL (9) or another untrapped
signal, then the callback will I<not> be called.

=item * double_fork

This mode will create a process that is detached from the parent process. The
double forked process will check if the parent is running by sending C<kill 0>
every two seconds. This mode might not be supported by all operating systems.

=item * fork

This mode will create a process with a pipe connected to the parent process.
Once the pipe is closed (when the parents ends) the callback will be called.
This should work in most processes, but will not work if a the process group
receives an unhandled signal.

=back

=head2 parse_sql

  @statements = parse_sql $type, $sql;
  @statements = parse_sql $uri_db, $sql;
  @statements = parse_sql "mysql", "insert into ...";

Takes either a string or an L<URI::db> object and a string containing SQL and
splits the SQL into a list of individual statements.

Currently only "mysql" is a supported type, meaning any other type will simply
return the input C<$sql>.

This is not required for SQLite though, you can do this instead:

  local $dbh->{sqlite_allow_multiple_statements} = 1;
  $dbh->do($sql);

=head1 SEE ALSO

L<DBIx::TempDB>.

=cut
