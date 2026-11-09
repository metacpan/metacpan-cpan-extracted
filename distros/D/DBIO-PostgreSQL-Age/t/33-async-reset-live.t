use strict;
use warnings;
use Test::More;

# LIVE (dbio-postgresql k154, core ADR 0079): a future_io pool connection is
# reset at the end of every borrow -- DISCARD ALL, then the connect actions
# again -- before the next borrower gets it.
#
# For AGE that means two things at once, in a pool of ONE connection so the
# second borrow is provably the first one's connection:
#   * what the first borrow set in the session is gone in the second (the reset
#     works), and
#   * LOAD 'age' and the ag_catalog search_path are back, so cypher() runs in
#     the second borrow without a schema prefix (the connect actions ran again;
#     DISCARD ALL alone would have left the connection without them).
#
# Creates one graph, dbio_k154_reset, and drops it. Needs the AGE extension.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_PG_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or plan skip_all =>
    'IO::Async, Future::IO::Impl::IOAsync and DBIO::Async required for the live future_io test';
}

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

use DBIO;

{
  package T::Age::ResetSchema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL::Age');
}

my $GRAPH = 'dbio_k154_reset';

my $schema = T::Age::ResetSchema->connect($dsn, $user, $pass, {
  async           => 'future_io',
  pool_size       => 1,
  on_connect_call => 'load_age',
});
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

my ($age) = $dbh->selectrow_array(
  q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'});
plan skip_all => 'Apache AGE extension not available in this PostgreSQL' unless $age;

sub graph_exists {
  my ($row) = $dbh->selectrow_array(
    q{SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?}, undef, $GRAPH);
  return $row;
}

$dbh->do('CREATE EXTENSION IF NOT EXISTS age');
$dbh->do(q{LOAD 'age'});
$dbh->do(q{SET search_path = ag_catalog, "$user", public});
$dbh->do("SELECT drop_graph('$GRAPH', true)") if graph_exists();
$dbh->do("SELECT create_graph('$GRAPH')");
END {
  $dbh->do("SELECT drop_graph('$GRAPH', true)") if $dbh && $dbh->{Active} && graph_exists();
}

my $async = $storage->async;
my $pool  = $async->pool;

sub query {
  my ($conn, $sql) = @_;
  return $async->_query_async_pinned($conn, $sql, [])->get;
}

# --- first borrow: leave a session variable behind ----------------------------
my $first = $pool->acquire->get;
my $dbh_first = $first->{dbh};
query($first, q{SELECT set_config('dbio_k154.marker', 'set by the first borrow', false)});
my ($seen) = @{ (query($first, q{SELECT current_setting('dbio_k154.marker', true)}))[0] };
is $seen, 'set by the first borrow', 'the first borrow sees its own session variable';
$pool->release($first);

# --- second borrow: same connection, reset, connect actions back --------------
my $second = $pool->acquire->get;
is $second->{dbh}, $dbh_first, 'the pool of one hands out the same connection again';

my ($gone) = @{ (query($second, q{SELECT current_setting('dbio_k154.marker', true)}))[0] };
ok !defined($gone) || $gone eq '', 'the session variable of the first borrow is gone (DISCARD ALL ran)'
  or diag "marker: $gone";

my ($path) = @{ (query($second, q{SELECT current_setting('search_path')}))[0] };
like $path, qr/ag_catalog/, 'ag_catalog is on the search_path again (connect actions replayed)';

my @rows = eval {
  query($second, "SELECT * FROM cypher('$GRAPH', \$\$ RETURN 1 \$\$) AS (r agtype)");
};
ok @rows, 'cypher() runs in the second borrow without a schema prefix (LOAD age is back)'
  or diag $@;
is $rows[0] && $rows[0][0], 1, '... and answers';
$pool->release($second);

$storage->disconnect;
done_testing;
