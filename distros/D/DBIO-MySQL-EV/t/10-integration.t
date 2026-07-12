use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  plan skip_all => 'Set DBIO_TEST_MYSQL_DSN to run integration tests'
    unless $ENV{DBIO_TEST_MYSQL_DSN};
}

use EV;
use EV::MariaDB;

# Parse DSN into conninfo hash
my $dsn = $ENV{DBIO_TEST_MYSQL_DSN};

my %conninfo;
if ($dsn =~ /^dbi:(?:mysql|mysql\.rdbs|mariadb):(.+)/i) {
  my $params = $1;
  for my $pair (split /;/, $params) {
    my ($k, $v) = split /=/, $pair, 2;
    $k = 'database' if $k eq 'dbname';
    $conninfo{$k} = $v if defined $k && defined $v;
  }
}
$conninfo{user}     = $ENV{DBIO_TEST_MYSQL_USER} if $ENV{DBIO_TEST_MYSQL_USER};
$conninfo{password} = $ENV{DBIO_TEST_MYSQL_PASS} if $ENV{DBIO_TEST_MYSQL_PASS};

# --- Basic connectivity via raw EV::MariaDB ---

my $connected = 0;
my $mdb;

$mdb = EV::MariaDB->new(
  %conninfo,
  on_connect => sub { $connected = 1 },
  on_error   => sub { diag "EV::MariaDB error: $_[0]"; $connected = -1 },
);

# Run event loop until connected
EV::run until $connected;

if ($connected < 0) {
  plan skip_all => "Could not connect to MySQL/MariaDB: check DBIO_TEST_MYSQL_DSN";
}

ok $connected > 0, 'connected to MySQL/MariaDB';
diag "Server version: " . $mdb->server_version // 'unknown';

# --- Simple query ---

{
  my $done = 0;
  my ($result_rows, $result_err);

  $mdb->query('SELECT 1 AS one', sub {
    ($result_rows, $result_err) = @_;
    $done = 1;
  });

  EV::run until $done;

  ok !$result_err, 'no error on SELECT 1';
  is $result_rows->[0][0], 1, 'got correct result from SELECT 1';
}

# --- Parameterized query ---

{
  my $done = 0;
  my ($rows, $err);

  $mdb->prepare('SELECT ? AS greeting', sub {
    my ($stmt, $perr) = @_;
    die "prepare failed: $perr" if $perr;
    $mdb->execute($stmt, ['hello DBIO'], sub {
      ($rows, $err) = @_;
      $done = 1;
    });
  });

  EV::run until $done;

  ok !$err, 'no error on parameterized query';
  is $rows->[0][0], 'hello DBIO', 'parameterized query works';
}

# --- Multiple queries chained ---

{
  my @results;
  my $done = 0;

  my @vals = (1..5);
  my $run_next; $run_next = sub {
    my $i = shift @vals;
    unless (defined $i) { $done = 1; return }
    $mdb->prepare('SELECT ? * 2 AS doubled', sub {
      my ($stmt, $perr) = @_;
      die "prepare failed: $perr" if $perr;
      $mdb->execute($stmt, [$i], sub {
        my ($rows, $err) = @_;
        push @results, $rows->[0][0] unless $err;
        $run_next->();
      });
    });
  };
  $run_next->();

  EV::run until $done;

  is_deeply \@results, [2, 4, 6, 8, 10],
    'chained queries all return correct results in order';
}

# --- Transaction ---

{
  my @steps;

  my $step = 0;
  $mdb->query('BEGIN', sub { push @steps, 'begin'; $step++ });
  EV::run until $step >= 1;

  $mdb->query("CREATE TEMPORARY TABLE _dbio_test (id INT AUTO_INCREMENT, name VARCHAR(255), PRIMARY KEY (id))", sub {
    push @steps, 'create';
    $step++;
  });
  EV::run until $step >= 2;

  $mdb->prepare("INSERT INTO _dbio_test (name) VALUES (?)", sub {
    my ($stmt, $perr) = @_;
    die "prepare failed: $perr" if $perr;
    $mdb->execute($stmt, ['Miles'], sub {
      push @steps, 'insert';
      $step++;
    });
  });
  EV::run until $step >= 3;

  my ($rows, $err);
  $mdb->query('SELECT name FROM _dbio_test', sub {
    ($rows, $err) = @_;
    push @steps, 'select';
    $step++;
  });
  EV::run until $step >= 4;

  $mdb->query('ROLLBACK', sub { push @steps, 'rollback'; $step++ });
  EV::run until $step >= 5;

  is_deeply \@steps, [qw/begin create insert select rollback/],
    'transaction steps executed in order';
  ok !$err, 'no error in transaction';
  is $rows->[0][0], 'Miles', 'data visible within transaction';
}

# --- Cleanup ---

$mdb->close_async(sub { });

done_testing;