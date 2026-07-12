use strict;
use warnings;
use Test::More;

# WP4a (karr #6) -- LIVE EV integration for AGE, built on the REUSABLE harness
# shipped by dbio-postgresql-ev (DBIO::PostgreSQL::EV::TestHarness), NOT on
# duplicated scaffolding. It proves the capstone claim end-to-end: the floating
# Age async layer composes over the native ev transport, and connect_call_load_age
# (LOAD 'age' + the ag_catalog search_path) replays on EVERY freshly-spawned EV
# pool connection (core karr #68) -- so a Cypher query runs on each of them.
#
# Fully gated: skips cleanly unless DBIO::PostgreSQL::EV is installed
# (develop/recommends dep, never a hard require) AND a live PG with the AGE
# extension is reachable via DBIO_TEST_PG_DSN.

BEGIN {
  eval { require DBIO::PostgreSQL::EV::TestHarness; 1 }
    or plan skip_all =>
      'DBIO::PostgreSQL::EV not installed (develop/recommends only) -- ev harness unavailable';
}

use DBIO::PostgreSQL::EV::TestHarness;

# Gate 1: live PG DSN + EV::Pg (the harness's own gate).
DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

# Gate 2: the AGE extension must be available in this cluster.
{
  require DBI;
  my ($dsn, $user, $pass) =
    @ENV{ map { "DBIO_TEST_PG_$_" } qw/DSN USER PASS/ };
  my $probe = DBI->connect($dsn, $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 0 });
  plan skip_all => "cannot connect: $DBI::errstr" unless $probe;
  my ($age) = $probe->selectrow_array(
    q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'});
  $probe->disconnect;
  plan skip_all => 'Apache AGE extension not available in this PostgreSQL' unless $age;
}

# An Age schema class: the component registers the Age storage layer, which core
# composes over the ev transport the harness selects with { async => 'ev' }.
{
  package T::Age::EvSchema;
  use base qw( DBIO::PostgreSQL::Age DBIO::Schema );
  use mro 'c3';
}

my $POOL  = 3;
my $GRAPH = 'dbio_age_ev_test_graph';

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  schema_class  => 'T::Age::EvSchema',
  connect_attrs => { on_connect_call => 'load_age', pool_size => $POOL },
);

# The composed ev backend really is the Age async layer over the EV transport.
my $async = $h->async;
isa_ok $async, 'DBIO::PostgreSQL::EV::Storage', 'ev backend isa the native EV transport';
isa_ok $async, 'DBIO::PostgreSQL::Age::Storage::Async',
  'ev backend carries the composed Age async layer (cypher_async available over ev)';
can_ok $async, 'cypher_async';

# --- Setup: create the extension + a graph with one vertex, on one connection.
my $setup = $h->await($h->pool->acquire);
eval {
  $h->await($h->query_on($setup, 'CREATE EXTENSION IF NOT EXISTS age'));
  # Reload age + search_path on this conn AFTER the extension exists, so DDL below
  # sees ag_catalog even if this connection spawned before the extension did.
  $h->await($h->query_on($setup, q{LOAD 'age'}));
  $h->await($h->query_on($setup, q{SET search_path = ag_catalog, "$user", public}));
  $h->await($h->query_on($setup, "SELECT ag_catalog.create_graph('$GRAPH')"));
  $h->await($h->query_on($setup,
    "SELECT * FROM cypher('$GRAPH', \$\$ CREATE (:Ping {msg: 'pong'}) RETURN 1 \$\$) AS (r agtype)"));
  1;
} or do {
  my $err = $@;
  $h->pool->release($setup);
  $h->disconnect;
  plan skip_all => "AGE graph setup failed on this cluster: $err";
};
$h->pool->release($setup);

# --- Per pooled connection: LOAD 'age' replayed -> a Cypher query runs there. ---
# run_on_each_pooled_connection forces $POOL DISTINCT spawns (each replays
# connect_call_load_age) and runs the code on each held connection.

# (a) The connect_call SET landed on every connection: search_path carries ag_catalog.
my @paths = $h->run_on_each_pooled_connection($POOL, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, q{SELECT current_setting('search_path')});
});
is scalar(@paths), $POOL, "$POOL distinct EV pool connections were exercised";
like $_->[0][0], qr/ag_catalog/,
  'LOAD age replayed on this pooled connection: search_path carries ag_catalog'
  for @paths;

# (b) A real Cypher query succeeds on every pooled connection -- which is only
# possible if LOAD 'age' replayed on it (cypher() + ag_catalog present there).
my $cypher_sql =
  "SELECT * FROM cypher('$GRAPH', \$\$ MATCH (n:Ping) RETURN n.msg \$\$) AS (msg agtype)";
my @rows = $h->run_on_each_pooled_connection($POOL, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, $cypher_sql);
});
like $_->[0][0], qr/pong/,
  'cypher_async-shaped query runs on this pooled EV connection (graph reachable, age loaded)'
  for @rows;

# (c) cypher_async end-to-end over the ev backend resolves to the sync row shape.
{
  my $rows = $h->await(
    $async->cypher_async($GRAPH, 'MATCH (n:Ping) RETURN n.msg', ['msg']),
  );
  is ref($rows), 'ARRAY', 'cypher_async over ev resolves to an arrayref of hashrefs';
  like $rows->[0]{msg}, qr/pong/, '... with the msg column keyed as sync cypher() returns';
}

# --- Cleanup: drop the test graph.
eval {
  my $c = $h->await($h->pool->acquire);
  $h->await($h->query_on($c, "SELECT ag_catalog.drop_graph('$GRAPH', true)"));
  $h->pool->release($c);
  1;
};

$h->disconnect;
done_testing;
