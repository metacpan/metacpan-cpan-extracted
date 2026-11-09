use strict;
use warnings;

use Test::More;
use DBI;
use IO::Handle;
use IO::Select;
use POSIX ();
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Deploy;

# LIVE (karr k69). DBIO::Sybase::Deploy->diff deploys the desired schema into
# a temporary database. Its size is calculated from the schema (t/93, t/31),
# so a schema normally fits; but `temp_db_size` sets it, and one too small --
# here the server's `default database size`, which a plain CREATE DATABASE
# gives -- is filled by the schema, and what the server does then is a
# database option:
#
#   without `abort tran on log full` -- what a database copied from `model`
#   has -- the session is not refused but SUSPENDED until somebody frees log
#   space (master..sysprocesses: status `sleeping`, cmd `LOG SUSPEND`). Nobody
#   does, so the statement never returns, and neither does diff() or
#   upgrade(). No error, no timeout.
#
#   with it the statement dies:
#     Msg 1105: Can't allocate space for object '..' in database '..' because
#     '..' segment is full/has no free extents. ..
#
# So _create_temp_db sets the option on the temporary database before anything
# is deployed into it.
#
# CLAIMED:
#
#   1. diff() on a schema too large for the temporary database RETURNS, within
#      a fixed time, and dies of the server's Msg 1105, which names the
#      temporary database.
#   2. The temporary database is dropped all the same, and the live handle is
#      in its own database afterwards.
#   3. sp_dboption's two messages of severity 10 ("Database option .. turned
#      ON ..", "Running CHECKPOINT on database ..") are not printed as
#      warnings: DBD::Sybase prints such a message when nothing takes it.
#
# THE SCHEMA is made here and sized by the server: a database of the default
# size is made, its free pages are counted, and it is dropped. The temporary
# database of diff() is then given that size with `temp_db_size`, so the room is the one
# the schema was derived from.
# Each table has a primary key and a unique index, and the server gives a
# table, its primary key and an index an extent of 8 pages each (measured
# here: 24 pages a table). There are free/16 + 1 tables, so even at 16 pages a
# table they do not fit -- at 24 they are half as much again as the room there
# is. Here: 686 free pages of 16K and 43 tables; a probe with the same tables
# had made 26 of them when the database was full.
#
# THIS FILE CANNOT HANG, whatever the code under test does: diff() runs in a
# child process, and the parent waits a fixed time for it and no longer. A
# child that has not answered by then is killed -- with SIGKILL, which asks
# nothing of the process; whether a Perl signal handler runs while DBD::Sybase
# waits for the server was not tried -- the sessions it left in its temporary
# database are ended with `kill <spid>`, the database is dropped, and the
# tests of 1 and 2 fail. Measured against a suspended session on the server
# named below: it is gone by itself within a second of the client's death;
# `kill <spid>` ends it at once too (the client sees "Unexpected EOF from the
# server"), and so does `select lct_admin('abort', <spid>, <dbid>)`, which
# fails the statement with Msg 7437 and Msg 1105 and leaves the session
# usable.
#
# NOT claimed:
#
#   * how large a schema fits, or how the size is calculated: t/93 and t/31.
#     DBIO::Test::Schema (36 tables) needs 733 pages and finds 686 in a
#     database of the default size.
#   * anything about a server where the temporary database's log is on a
#     device of its own, or about the Sybase Open Client libraries.
#
# Measured 2026-10-08 against SAP ASE 16.0 SP02 PL02 (16K pages), with
# DBD::Sybase 1.27 built against FreeTDS 1.3.17, TDS 5.0.
#
# Makes one database of the default size and drops it, beside the temporary
# one of diff(), and reads the database of the DSN; needs a login allowed to
# CREATE DATABASE and to set a database option (sa on the docker/k8s ASE
# image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

# How long diff() may take. With the option set it took a second here.
my $LIMIT = 60;

# More tables than this would make the test long; see below.
my $MOST_TABLES = 200;

{
  package T::K69::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

# AutoInactiveDestroy: the child below inherits this handle and must not
# close the session when it goes.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1, AutoInactiveDestroy => 1,
    });
    $dbh->do('use master');
    $dbh;
  };
}

sub server_column { @{ admin()->selectcol_arrayref(@_) } }

# The databases of this test: the one made here, and the temporary ones of
# DBIO::Sybase::Deploy in the child, which have the child's process id.
my $child;
sub databases_there {
  return server_column(sprintf
    q{select name from master..sysdatabases where name like 'dbio[_]k69[_]%d[_]%%' %s order by name},
    $$,
    ( $child ? sprintf(q{or name like '[_]dbio[_]tmp[_]%d[_]%%'}, $child) : '' ),
  );
}

sub sessions_in {
  return @{ admin()->selectall_arrayref(
    "select spid, status, cmd from master..sysprocesses where dbid = db_id('$_[0]')"
  ) };
}

# Ends what is in the database and drops it. Returns what the server kept.
sub clear_away {
  my $db = shift;
  for my $session (sessions_in($db)) {
    my ($spid, $status, $cmd) = map { s/\s+\z//r } @$session;
    diag "  ending session $spid in $db ($status, $cmd)";
    eval { admin()->do("kill $spid") };   # it may have gone by itself
  }
  my $said = AseDatabase::drop(admin(), $db);
  return $said ? "$db: $said" : ();
}

# The server's words, without the rest of the exception.
sub said {
  my $text = shift // '';
  my (@messages, %seen);
  while ($text =~ /Server\ message\ number=(\d+) [^\n]*? \btext=(.*?) \s*
                   (?= Server\ message\ number= | \[for\ Statement | \ at\ \S+\ line\ \d+ | \z )/gsx) {
    push @messages, "Msg $1: $2" unless $seen{"$1: $2"}++;
  }
  return join ' | ', @messages if @messages;
  $text =~ s/\s+/ /g;
  return $text;
}

my $live = 1;   # past the skip_all: from here on there is something to drop

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );

# ============================ the room a temporary database has, and the schema

my ($free, $megabytes) = do {
  my $db = "dbio_k69_${$}_room";
  admin()->do("create database $db");
  my ($pages, $size) = admin()->selectrow_array(
    'select sum(curunreservedpgs(dbid, lstart, unreservedpgs)), '
  . '       sum(size) * @@maxpagesize / 1048576 '
  . "from master..sysusages where dbid = db_id('$db')"
  );
  my $kept = AseDatabase::drop(admin(), $db);
  die "in the way of this test: $db: $kept\n" if $kept;
  ($pages, $size);
};

my $tables = int( $free / 16 ) + 1;

# A server whose default database is large is not at risk in the way this file
# is about, and deploying thousands of tables to say so is not worth it.
plan skip_all => "a database of the server's default size has $free free pages: "
               . "room for more than $MOST_TABLES tables"
  if $tables > $MOST_TABLES;

note "a database of the server's default size ($megabytes MB) has $free free pages; "
   . "the schema has $tables tables, each with a primary key and a unique index";

for my $n (1 .. $tables) {
  my $class = sprintf 'T::K69::Result::T%03d', $n;
  my $table = sprintf 'k69_t%03d', $n;
  {
    no strict 'refs';
    @{"${class}::ISA"} = ('DBIO::Core');
  }
  $class->table($table);
  $class->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  $class->set_primary_key('id');
  $class->add_unique_constraint("${table}_name" => ['name']);
  T::K69::Schema->register_class(sprintf('T%03d', $n) => $class);
}

# ====================================================== diff(), in a child

pipe(my $from_child, my $to_parent) or die "pipe: $!";

$child = fork // die "fork: $!";

if (!$child) {
  # Everything the parent is to know goes down the pipe, one line each; the
  # child prints no test output and leaves without END blocks.
  close $from_child;
  $to_parent->autoflush(1);
  my $tell = sub { print {$to_parent} join(' ', map { s/\s+/ /gr } @_), "\n" };
  local $SIG{__WARN__} = sub { $tell->(warned => @_) };

  eval {
    my $schema = T::K69::Schema->connect($dsn, $user, $pass);
    my $dbh    = $schema->storage->dbh;
    my $in     = sub { ( $dbh->selectrow_array('select db_name()') )[0] };

    $tell->(before => $in->());

    my $started = Time::HiRes::time;
    my $diff    = eval { DBIO::Sybase::Deploy->new(schema => $schema, temp_db_size => "${megabytes}M")->diff };
    my $error   = $@;

    $tell->(seconds => sprintf '%.1f', Time::HiRes::time - $started);
    $tell->($diff ? ( outcome => 'returned a diff' ) : ( outcome => 'died' ));
    $tell->(error => $error) unless $diff;
    $tell->(after => $in->());

    $schema->storage->disconnect;
    1;
  } or $tell->(broken => $@);

  close $to_parent;
  POSIX::_exit(0);
}

close $to_parent;

# Until the child closes the pipe -- it is done -- or the time is over.
my $deadline = Time::HiRes::time + $LIMIT;
my $answer   = '';
my $done     = 0;
my $select   = IO::Select->new($from_child);
while (( my $left = $deadline - Time::HiRes::time ) > 0) {
  last unless $select->can_read($left);
  my $read = sysread $from_child, $answer, 65536, length $answer;
  next if $read;
  $done = defined $read;   # end of file: the child has closed the pipe
  last;
}

# A child that has not answered: what its sessions in the temporary database
# are doing, looked at before it is killed -- they go with it.
my @waiting;
unless ($done) {
  @waiting = map {
    my $db = $_;
    map { "$db: session " . join(' ', map { s/\s+\z//r } @$_) } sessions_in($db);
  } grep { /^_dbio_tmp_/ } databases_there();
  kill KILL => $child;
}
waitpid $child, 0;
my $reaped = 1;   # its process id is nobody's to signal from here on

my (%told, @warned);
for my $line (split /\n/, $answer) {
  my ($key, $value) = split / /, $line, 2;
  if ($key eq 'warned') { push @warned, $value } else { $told{$key} = $value // '' }
}

# What the child left on the server, before anything is cleared away.
my @left = grep { /^_dbio_tmp_/ } databases_there();

# ================================================================ 1. it returns

ok $done, "diff() on a schema of $tables tables returned within $LIMIT seconds"
  or diag '  it did not, and was killed. In its temporary database (spid, '
        . 'status, cmd):', map { "\n  $_" } @waiting;

note "diff() took $told{seconds} seconds" if defined $told{seconds};
diag "  the child could not run the test: $told{broken}" if defined $told{broken};

is $told{outcome}, 'died',
  '... and it died: the schema does not fit into the temporary database';

like $told{error} // '(nothing came back)',
  qr/Server message number=1105 [^\n]*\bin database '_dbio_tmp_${child}_\d+_\d+'/,
  '... of the server\'s Msg 1105, which names the temporary database'
  or diag '  ' . said($told{error});

note '  ' . said($told{error}) if defined $told{error};

# =========================================== 2. nothing left, handle at home

is_deeply \@left, [], 'the temporary database is dropped all the same';

ok defined $told{before} && defined $told{after} && $told{before} eq $told{after},
  'the live handle is in its own database afterwards'
  or diag '  before: ' . ( $told{before} // '(not told)' )
        . ', after: ' . ( $told{after} // '(not told)' );

# ========================================================= 3. no chatter

is_deeply [ grep { /Database option|CHECKPOINT/ } @warned ], [],
  'sp_dboption\'s messages about the temporary database are not printed as warnings';

note "  warned: $_" for @warned;

# ================================================================ the end

my @kept = map { clear_away($_) } databases_there();
diag "  $_" for @kept;

is_deeply [ databases_there() ], [], 'nothing of this test is left on the server';

done_testing;

# Again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    if ($child and not $reaped) { kill KILL => $child; waitpid $child, 0 }
    undef $admin;
    my @kept = eval { map { clear_away($_) } databases_there() };
    diag "Could not clean up after this test: $_" for ( $@ ? said($@) : () ), @kept;
  }
}
