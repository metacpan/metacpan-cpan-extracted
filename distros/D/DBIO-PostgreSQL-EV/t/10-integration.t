use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::Util ();
use DBIO::PostgreSQL::EV::ConnectInfo ();

# The test login as the conninfo string the transport hands EV::Pg; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;
my $conninfo = DBIO::PostgreSQL::EV::ConnectInfo::conninfo_string({ LiveServer->conninfo });

# --- Basic connectivity via raw EV::Pg ---

my $connected = 0;
my $pg;

$pg = EV::Pg->new(
  conninfo   => $conninfo,
  on_connect => sub { $connected = 1 },
  on_error   => sub {
    diag 'EV::Pg error: ' . DBIO::Util::mask_connect_secrets("$_[0]", [ LiveServer->login ]);
    $connected = -1;
  },
);

# Run event loop until connected
EV::run until $connected;

# The server took a DBI connection a moment ago (require_server): EV::Pg not
# connecting to it from the same login is a failure, and nothing below can run.
unless ($connected > 0) {
  fail 'connected to PostgreSQL';
  done_testing;
  exit;
}

pass 'connected to PostgreSQL';
diag "Server version: " . $pg->server_version;

# --- Simple query ---

{
  my $done = 0;
  my ($result_rows, $result_err);

  $pg->query('SELECT 1 AS one', sub {
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

  $pg->query_params('SELECT $1::text AS greeting', ['hello DBIO'], sub {
    ($rows, $err) = @_;
    $done = 1;
  });

  EV::run until $done;

  ok !$err, 'no error on parameterized query';
  is $rows->[0][0], 'hello DBIO', 'parameterized query works';
}

# --- Multiple queries chained ---

{
  my @results;
  my $done = 0;

  # EV::Pg processes one query at a time per connection (outside pipeline),
  # so we chain them in callbacks
  my @vals = (1..5);
  my $run_next; $run_next = sub {
    my $i = shift @vals;
    unless (defined $i) { $done = 1; return }
    $pg->query_params('SELECT $1::int * 2 AS doubled', [$i], sub {
      my ($rows, $err) = @_;
      push @results, $rows->[0][0] unless $err;
      $run_next->();
    });
  };
  $run_next->();

  EV::run until $done;

  is_deeply \@results, [2, 4, 6, 8, 10],
    'chained queries all return correct results in order';
}

# --- Pipeline mode ---

{
  $pg->enter_pipeline;

  my @results;
  my $count = 0;

  for my $i (1..3) {
    $pg->query_params('SELECT $1::int AS num', [$i], sub {
      my ($rows, $err) = @_;
      push @results, $rows->[0][0] unless $err;
      $count++;
    });
  }

  my $synced = 0;
  $pg->pipeline_sync(sub { $synced = 1 });

  EV::run until $synced;
  $pg->exit_pipeline;

  is scalar @results, 3, 'pipeline returned 3 results';
  is_deeply [sort { $a <=> $b } @results], [1, 2, 3],
    'pipeline mode returns correct results';
}

# --- Prepared statement ---

{
  my $prepared = 0;
  $pg->prepare('test_add', 'SELECT $1::int + $2::int AS sum', sub {
    $prepared = 1;
  });

  EV::run until $prepared;

  my $done = 0;
  my ($rows, $err);
  $pg->query_prepared('test_add', [17, 25], sub {
    ($rows, $err) = @_;
    $done = 1;
  });

  EV::run until $done;

  ok !$err, 'prepared statement executed without error';
  is $rows->[0][0], 42, 'prepared statement returns correct result';
}

# --- Transaction ---

{
  my @steps;

  my $step = 0;
  $pg->query('BEGIN', sub { push @steps, 'begin'; $step++ });
  EV::run until $step >= 1;

  $pg->query("CREATE TEMP TABLE _dbio_test (id serial, name text)", sub {
    push @steps, 'create';
    $step++;
  });
  EV::run until $step >= 2;

  $pg->query_params("INSERT INTO _dbio_test (name) VALUES (\$1)", ['Miles'], sub {
    push @steps, 'insert';
    $step++;
  });
  EV::run until $step >= 3;

  my ($rows, $err);
  $pg->query('SELECT name FROM _dbio_test', sub {
    ($rows, $err) = @_;
    push @steps, 'select';
    $step++;
  });
  EV::run until $step >= 4;

  $pg->query('ROLLBACK', sub { push @steps, 'rollback'; $step++ });
  EV::run until $step >= 5;

  is_deeply \@steps, [qw/begin create insert select rollback/],
    'transaction steps executed in order';
  ok !$err, 'no error in transaction';
  is $rows->[0][0], 'Miles', 'data visible within transaction';
}

# --- Cleanup ---

$pg->finish;

done_testing;
