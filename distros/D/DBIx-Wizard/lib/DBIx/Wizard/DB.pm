package DBIx::Wizard::DB;

use strict;
use DBI;
use Carp;

my %h_dsn;
my %h_user;
my %h_password;
my %h_options;
my %h_dbh;
my %h_inflate_class;

sub declare {
  my ($class, $db, $dsn, $user, $password, $rh_options) = @_;

  # Extract inflate_class from options (not a DBI option)
  my $inflate_class = delete $rh_options->{inflate_class};
  $h_inflate_class{$db} = $inflate_class if $inflate_class;

  $h_dsn{$db}      = $dsn;
  $h_user{$db}     = $user;
  $h_password{$db} = $password;
  $h_options{$db}  = $rh_options || {};
}

sub inflate_class {
  my ($class, $db) = @_;
  return $h_inflate_class{$db};
}

sub _declare_from_env {
  my ($class, $db) = @_;

  my $env_key = 'DBIW_DECLARE_' . uc($db);
  my $env_val = $ENV{$env_key};
  return unless $env_val;

  my ($dsn, $user, $password) = split /\|/, $env_val, 3;
  $class->declare($db, $dsn, $user // '', $password // '');
}

sub dbh {
  my ($class, $db) = @_;

  # Try environment-based declaration if not already declared
  if (!$h_dsn{$db}) {
    $class->_declare_from_env($db);
  }

  if (!$h_dsn{$db}) {
    croak "DBIW: undeclared db: $db (set DBIW_DECLARE_" . uc($db) . " or call DBIx::Wizard::DB->declare)";
  }

  if ($h_dbh{$db}) {
    return $h_dbh{$db};
  }

  my $mysql_enable_utf8_after_connect = delete $h_options{$db}{mysql_enable_utf8_after_connect};

  my $dbh = DBI->connect($h_dsn{$db}, $h_user{$db}, $h_password{$db}, $h_options{$db});

  if ($mysql_enable_utf8_after_connect) {
    $dbh->{mysql_enable_utf8} = 1;
  }

  $h_dbh{$db} = $dbh;

  return $dbh;
}

sub dbname {
  my ($class, $db) = @_;

  my $dbh = $class->dbh($db);

  if ($dbh->{Driver}->{Name} =~ m/mysql|MariaDB/) {
    if ($dbh->{Name} =~ m/database=([^;]+)/) {
      return $1;
    } else {
      (my $dbname = $dbh->{Name}) =~ s/:.*//;
      return $dbname;
    }
  } elsif ($dbh->{Driver}->{Name} eq 'Pg') {
    if ($dbh->{Name} =~ m/dbname=([^;]+)/) {
      return $1;
    }
  } elsif ($dbh->{Driver}->{Name} eq 'SQLite') {
    if ($dbh->{Name} =~ m/dbname=([^;]+)/) {
      return $1;
    }
  }

  croak "DBIW: unsupported database driver: " . $dbh->{Driver}->{Name};
}

sub catalog {
  return undef;
}

## DB wrapper (returned by dbiw('dbname') without table)

sub wrapper {
  my ($class, $db) = @_;
  return bless { db => $db }, "${class}::Wrapper";
}

package DBIx::Wizard::DB::Wrapper;

use strict;
use Carp;

my $savepoint_counter = 0;

sub dbh {
  my ($self) = @_;
  return DBIx::Wizard::DB->dbh($self->{db});
}

sub transaction {
  my ($self, $code) = @_;
  croak "transaction requires a code reference" if (ref($code) ne 'CODE');

  my $dbh = $self->dbh;

  if ($dbh->{AutoCommit}) {
    # Outer transaction
    $dbh->begin_work;
    eval { $code->(); $dbh->commit; 1 }
      or do { my $err = $@; $dbh->rollback; die $err };
  } else {
    # Already in a transaction — use savepoint
    my $sp = "dbiw_sp_" . ++$savepoint_counter;
    $dbh->do("SAVEPOINT $sp");
    eval { $code->(); $dbh->do("RELEASE SAVEPOINT $sp"); 1 }
      or do { my $err = $@; $dbh->do("ROLLBACK TO SAVEPOINT $sp"); die $err };
  }
}

1;
