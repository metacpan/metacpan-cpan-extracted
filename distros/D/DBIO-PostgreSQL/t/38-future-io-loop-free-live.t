use strict;
use warnings;
use Test::More;

# LIVE: the event loop stays free while a long statement runs over the
# future_io transport (karr k134).
#
# t/17 shows parallelism between connections; this shows the transport itself
# does not block. A pg_sleep(1) goes out over one pool connection, a timer
# ticks every 50 ms meanwhile, and a short statement on a second connection
# finishes before the long one. A transport that waited on the socket
# synchronously would let no tick fire until the statement was done.

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
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io test';
}

use Future;
use Future::IO;
use Time::HiRes ();
use DBIO::Test;

# DBIO::Test::Schema keeps no driver in its class: this file runs it on
# PostgreSQL (core ADR 0067).
DBIO::Test::Schema->storage_type('+DBIO::PostgreSQL::Storage');

eval { require DBIO::PostgreSQL::Storage::Async; 1 }
  or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

my $schema = DBIO::Test::Schema->connect($dsn, $user, $pass, { async => 'future_io' });
my $async  = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::Storage::Async', 'the future_io transport';

my $long_conn  = $async->pool->acquire->get;
my $short_conn = $async->pool->acquire->get;
isnt $long_conn, $short_conn, 'two distinct pool connections';

# the tick: every 50 ms until told to stop
my ($ticks, $running) = (0, 1);
my $tick; $tick = sub {
  return Future->done unless $running;
  return Future::IO->sleep(0.05)->then(sub { $ticks++ if $running; $tick->() });
};
my $timer = $tick->();

my $t0 = Time::HiRes::time();
my ($long_done, $short_done);

my $long = $async->_query_async_pinned($long_conn, 'SELECT pg_sleep(1)', [])
  ->on_done(sub { $long_done = Time::HiRes::time() });
ok !$long->is_ready, 'the long statement is pending right after the call';

my $short = $async->_query_async_pinned($short_conn, 'SELECT 1', [])
  ->on_done(sub { $short_done = Time::HiRes::time() });

my $guard = Future::IO->sleep(10)->then(sub { Future->fail("not finished in 10 s\n") });
Future->wait_any(Future->needs_all($long, $short)->without_cancel, $guard)->get;
$running = 0;

ok $long->is_done && $short->is_done, 'both statements finished';
my $elapsed = $long_done - $t0;
cmp_ok $elapsed, '>=', 0.95, "the long statement really ran (took ${\ sprintf '%.2f', $elapsed} s)";
cmp_ok $ticks, '>=', 15, "the loop stayed free: $ticks timer ticks of 50 ms during it";
cmp_ok $short_done, '<', $long_done,
  'the short statement on the second connection finished before the long one';

$async->pool->release($_) for $long_conn, $short_conn;
$async->disconnect;

done_testing;
