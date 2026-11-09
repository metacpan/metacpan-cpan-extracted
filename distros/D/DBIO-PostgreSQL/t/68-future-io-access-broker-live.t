use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE: built-in AccessBrokers on the future_io transport against a real
# PostgreSQL (karr k80). The offline half, t/67-future-io-access-broker.t, pins
# the exact DBI->connect arguments for every broker shape; this file shows that
# those arguments reach a real server and authenticate:
#
#   a) a Static broker (host / port / dbname taken apart from the test DSN)
#      attached to the transport: a select_async runs on a pool connection
#      logged in as the broker's user to the broker's database, and a
#      notify / listen round trip works -- the listen connection is opened
#      from the broker too;
#   b) a Vault broker whose (stub) Vault client issues the live credentials,
#      through MyApp::Schema->connect($vault) with dbi_attrs
#      { async => 'future_io' }: a select_async runs as that user;
#   c) the connect options beside a Static broker (karr k91), through
#      MyApp::Schema->connect($static, { async => 'future_io', pool_size => 2,
#      pg_server_prepare => 0 }): four statements sent at once run on exactly
#      two server backends -- the pool is the size given beside the broker,
#      where the default would have opened four -- and the pooled connection
#      carries the DBD attribute given beside it.
#
# Gated like the other live tests: needs DBIO_TEST_PG_DSN, _USER and _PASS.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io broker test';
}

use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::Util ();
use Future;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# The Static broker needs the DSN's parts: the DSN read as DBD::Pg and libpq
# read it, not taken apart here (karr k113).
my %part = LiveServer->conninfo;
# The DSN is named without a password it may carry (karr k111).
plan skip_all => 'cannot take the test DSN apart into dbname / host / port: '
  . DBIO::Util::mask_connect_secrets($dsn, [ $dsn, $user, $pass ])
  unless defined $part{dbname};

my $loop = IO::Async::Loop->new;

# Run the loop until $cond holds or $timeout passes. Never open-ended.
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

# Who and where the connection that runs it is logged in.
sub whoami {
  my ($async) = @_;
  my ($row) = $async->select_async(
    'pg_catalog.pg_stat_activity', [ 'usename', 'datname' ],
    { pid => \'= pg_backend_pid()' },
  )->get;
  return $row;
}

subtest 'a) Static broker: select_async and a notify / listen round trip' => sub {
  my $broker = DBIO::AccessBroker::Static->new(
    dbname   => $part{dbname},
    (defined $part{host} ? (host => $part{host}) : ()),
    (defined $part{port} ? (port => $part{port}) : ()),
    username => $user,
    password => $pass,
  );
  my $async = DBIO::PostgreSQL::Storage::Async->new(undef);
  $async->connect_info([ $broker ]);

  is_deeply whoami($async), [ $user, $part{dbname} ],
    'select_async ran on a pool connection opened from the broker: its user, its database';

  my $channel = "dbio_k80_${$}_static";
  my @got;
  $async->listen($channel => sub { push @got, [@_] })->get;
  my $listen_dbh = $async->{_listen}{conn}{dbh};
  is_deeply [ $listen_dbh->{pg_user}, $listen_dbh->{pg_db} ], [ $user, $part{dbname} ],
    'the listen connection was opened from the broker too';

  $async->notify($channel => 'from the broker')->get;
  ok wait_until(sub { @got }), 'the notification sent on a pool connection arrived';
  is_deeply [ map { @$_[0, 1] } @got ], [ $channel, 'from the broker' ],
    '... on its channel, with its payload';

  $async->unlisten($channel)->get;
  $async->disconnect;
};

{
  package LiveVaultClient;
  sub new { my ($class, %creds) = @_; bless { creds => \%creds }, $class }
  sub read_secret { return { %{ $_[0]{creds} } } }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

subtest 'b) Vault broker through MyApp::Schema->connect: select_async' => sub {
  my $vault = DBIO::AccessBroker::Vault->new(
    vault     => LiveVaultClient->new(username => $user, password => $pass),
    dsn       => $dsn,
    cred_path => 'database/creds/dbio_test',
    dbi_attrs => { async => 'future_io' },
  );
  my $schema = BrokerSchema->connect($vault);
  my $async = $schema->storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io backend';

  is_deeply whoami($async), [ $user, $part{dbname} ],
    'select_async ran on a pool connection logged in with the credentials Vault issued';

  $async->disconnect;
};

subtest 'c) options beside a Static broker: pool_size and a DBD attribute' => sub {
  my $static = DBIO::AccessBroker::Static->new(
    dbname   => $part{dbname},
    (defined $part{host} ? (host => $part{host}) : ()),
    (defined $part{port} ? (port => $part{port}) : ()),
    username => $user,
    password => $pass,
  );
  my $schema = BrokerSchema->connect($static, {
    async => 'future_io', pool_size => 2, pg_server_prepare => 0,
  });
  my $async = $schema->storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io backend';

  # All four are sent before any is collected, so each one that finds no idle
  # connection makes the pool open another -- up to its size.
  my @rows = Future->needs_all(
    map { $async->_query_async('SELECT pg_backend_pid(), pg_sleep(0.1)', []) } 1 .. 4
  )->get;
  my %backend = map { $_->[0] => 1 } @rows;
  is scalar(@rows), 4, 'four statements sent at once all ran';
  is scalar(keys %backend), 2,
    '... on exactly two server backends: pool_size beside the broker sized the pool';

  my $conn = $async->pool->acquire->get;
  is $conn->{dbh}{pg_server_prepare}, 0,
    'a pooled connection carries pg_server_prepare => 0, given beside the broker';
  $async->pool->release($conn);

  $async->disconnect;
};

done_testing;
