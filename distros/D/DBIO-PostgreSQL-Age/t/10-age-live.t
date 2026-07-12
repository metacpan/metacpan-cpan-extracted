use strict;
use warnings;
use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Storage; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';

# Probe the cluster for the AGE extension before doing anything else.
require DBI;
my $probe = DBI->connect($dsn, $user, $pass, {
  AutoCommit => 1, RaiseError => 0, PrintError => 0,
});
plan skip_all => "cannot connect: $DBI::errstr" unless $probe;

my ($age_available) = $probe->selectrow_array(
  q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'}
);
$probe->disconnect;
plan skip_all => 'Apache AGE extension not available in this PostgreSQL'
  unless $age_available;

use_ok('DBIO::PostgreSQL::Age');
use_ok('DBIO::PostgreSQL::Age::Storage');

# Set up a minimal schema using the Age component.
{
  package TestAgeSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::Age');
}

my $schema = TestAgeSchema->connect(
  $dsn, $user, $pass,
  {
    AutoCommit      => 1,
    RaiseError      => 1,
    PrintError      => 0,
    on_connect_call => 'load_age',
  },
);

isa_ok($schema->storage, 'DBIO::PostgreSQL::Age::Storage', 'storage class');
isa_ok($schema->storage, 'DBIO::PostgreSQL::Storage', 'inherits from PostgreSQL::Storage');

# Make sure the extension is created in the test database.
$schema->storage->dbh->do('CREATE EXTENSION IF NOT EXISTS age');

# Force a connection so on_connect_call fires.
ok($schema->storage->dbh->ping, 'connected to PostgreSQL');

my $graph = 'dbio_age_test_' . $$;

# Cleanup any leftover graph from a previous interrupted run.
eval { $schema->storage->drop_graph($graph, 1) };

END {
  return unless $schema && $schema->storage;
  eval { $schema->storage->drop_graph($graph, 1) };
}

# --- create_graph ---
lives_ok { $schema->storage->create_graph($graph) } 'create_graph lives';

my ($exists) = $schema->storage->dbh->selectrow_array(
  'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?',
  undef, $graph,
);
ok($exists, 'graph appears in ag_catalog.ag_graph');

# --- cypher: insert a few vertices and edges ---
# AGE requires at least one return column from cypher(), so each CREATE
# returns a literal value we can ignore.
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{
      CREATE (alice:Person {name: 'Alice', age: 30}),
             (bob:Person   {name: 'Bob',   age: 25}),
             (carol:Person {name: 'Carol', age: 28}),
             (alice)-[:KNOWS {since: 2020}]->(bob),
             (bob)-[:KNOWS {since: 2021}]->(carol),
             (alice)-[:KNOWS {since: 2019}]->(carol)
      RETURN 1
    },
    ['ok'],
  );
} 'cypher CREATE lives';

# --- cypher: query vertices ---
my $rows = $schema->storage->cypher(
  $graph,
  q{ MATCH (p:Person) RETURN p.name },
  ['name'],
);

is(ref $rows, 'ARRAY', 'cypher returns arrayref');
is(scalar @$rows, 3, 'three persons matched');

my @names = sort map { my $n = $_->{name}; $n =~ s/^"|"$//g; $n } @$rows;
is_deeply(\@names, [qw(Alice Bob Carol)], 'all three names returned');

# --- cypher: traverse relationship ---
my $knows = $schema->storage->cypher(
  $graph,
  q{ MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a.name, b.name },
  [qw(a b)],
);
is(scalar @$knows, 3, 'three KNOWS edges traversed');

# --- cypher with parameters ---
my $alice = $schema->storage->cypher(
  $graph,
  q{ MATCH (p:Person {name: $name}) RETURN p.age },
  ['age'],
  { name => 'Alice' },
);
is(scalar @$alice, 1, 'parameterized query returns one row for Alice');
like($alice->[0]{age}, qr/30/, 'Alice age is 30');

# --- WHERE: filter by property ---
my $adults = $schema->storage->cypher(
  $graph,
  q{ MATCH (p:Person) WHERE p.age >= 28 RETURN p.name },
  ['name'],
);
is(scalar @$adults, 2, 'WHERE filters to two adults (>= 28)');

# --- ORDER BY: sorted traversal ---
my $ordered = $schema->storage->cypher(
  $graph,
  q{ MATCH (p:Person) RETURN p.name ORDER BY p.name },
  ['name'],
);
my @ordered_names = map { my $n = $_->{name}; $n =~ s/^"|"$//g; $n } @$ordered;
is_deeply(\@ordered_names, [qw(Alice Bob Carol)], 'ORDER BY returns alphabetic names');

# --- SET: update a vertex property ---
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{ MATCH (p:Person {name: 'Bob'}) SET p.age = 26 RETURN p.age },
    ['age'],
  );
} 'SET lives';
my $bobs_age = $schema->storage->cypher(
  $graph, q{ MATCH (p:Person {name: 'Bob'}) RETURN p.age }, ['age'],
);
like($bobs_age->[0]{age}, qr/26/, 'SET updated Bob age to 26');

# --- REMOVE: drop a property, then add it back so later queries still pass ---
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{ MATCH (p:Person {name: 'Bob'}) REMOVE p.age RETURN p.name },
    ['name'],
  );
} 'REMOVE lives';
my $bob_no_age = $schema->storage->cypher(
  $graph, q{ MATCH (p:Person {name: 'Bob'}) RETURN p.age }, ['age'],
);
is(scalar @$bob_no_age, 1, 'Bob still exists after REMOVE');
ok(!defined($bob_no_age->[0]{age}) || $bob_no_age->[0]{age} eq 'null',
  'Bob has no age after REMOVE (null)');
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{ MATCH (p:Person {name: 'Bob'}) SET p.age = 26 RETURN 1 },
    ['ok'],
  );
} 'restore Bob age for downstream tests';

# --- MERGE: idempotent create ---
# AGE 1.7.0 does not support ON CREATE / ON MATCH clauses, only plain MERGE.
# Plain MERGE on an existing vertex is a no-op (no duplicate, no overwrite).
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{
      MERGE (d:Person {name: 'Dave'})
      SET d.age = 40
      RETURN 1
    },
    ['ok'],
  );
} 'MERGE creates Dave';
lives_ok {
  $schema->storage->cypher(
    $graph,
    q{
      MERGE (d:Person {name: 'Dave'})
      SET d.age = 40
      RETURN 1
    },
    ['ok'],
  );
} 'MERGE on Dave again is idempotent (still one row, no error)';
my $dave = $schema->storage->cypher(
  $graph, q[ MATCH (d:Person {name: 'Dave'}) RETURN d.age ], ['age'],
);
is(scalar @$dave, 1, 'Dave exists exactly once after two MERGEs');
like($dave->[0]{age}, qr/40/, 'Dave age is 40');
my $dave_count = $schema->storage->cypher(
  $graph, q[ MATCH (d:Person {name: 'Dave'}) RETURN d ], ['d'],
);
is(scalar @$dave_count, 1, 'no duplicate Dave was created');

# --- OPTIONAL MATCH: missing relationship yields null, not absence ---
my $optional = $schema->storage->cypher(
  $graph,
  q{
    MATCH (p:Person {name: 'Alice'})
    OPTIONAL MATCH (p)-[:KNOWS]->(lone:Person {name: 'NobodyHere'})
    RETURN p.name, lone.name
  },
  [qw(host guest)],
);
is(scalar @$optional, 1, 'OPTIONAL MATCH still returns the host row');
ok(!defined($optional->[0]{guest}) || $optional->[0]{guest} eq 'null',
  'OPTIONAL MATCH yields null for the missing branch');

# --- WITH + aggregation: count how many people each person knows ---
# Alice -> {Bob, Carol} = 2 outgoing; Bob -> Carol = 1; Carol -> 0.
# So WITH a, count(b) yields two groups (Alice=2, Bob=1).
my $degree = $schema->storage->cypher(
  $graph,
  q{
    MATCH (a:Person)-[:KNOWS]->(b:Person)
    WITH a, count(b) AS degree
    RETURN a.name, degree
    ORDER BY a.name
  },
  [qw(name degree)],
);
is(scalar @$degree, 2, 'two people have outgoing KNOWS edges (Alice and Bob)');
like($degree->[0]{degree}, qr/2/, 'Alice (sorted first) knows 2 people');
like($degree->[1]{degree}, qr/1/, 'Bob knows 1 person');

# --- variable-length path: who does Alice reach in 1..2 hops? ---
# Alice->Bob (1 hop), Alice->Carol (1 hop), Alice->Bob->Carol (2 hops).
# DISTINCT collapses Bob and Carol; with Dave added separately via MERGE above,
# Dave has no outgoing KNOWS, so he is not reachable from Alice.
my $reachable = $schema->storage->cypher(
  $graph,
  q{
    MATCH (a:Person {name: 'Alice'})-[:KNOWS*1..2]->(b:Person)
    RETURN DISTINCT b.name
  },
  ['name'],
);
my @reachable_names = sort map { my $n = $_->{name}; $n =~ s/^"|"$//g; $n } @$reachable;
is_deeply(\@reachable_names, [qw(Bob Carol)],
  'variable-length path [*1..2] from Alice reaches Bob and Carol');

# --- Edge properties in projection ---
# Use non-reserved column names — 'from' and 'to' are SQL keywords.
my $with_edge = $schema->storage->cypher(
  $graph,
  q{
    MATCH (a:Person {name: 'Alice'})-[r:KNOWS]->(b:Person)
    RETURN a.name, b.name, r.since
  },
  [qw(src dst since)],
);
is(scalar @$with_edge, 2, 'Alice has two KNOWS edges');
like($with_edge->[0]{since}, qr/^"?20\d\d"?$/, 'edge property since is a year');

# --- auto_decode: cypher() option returns structured Perl data ---
my $decoded = $schema->storage->cypher(
  $graph,
  q[ MATCH (p:Person {name: $name}) RETURN p.age, p.name ],
  [qw(age name)],
  { name => 'Alice' },
  { auto_decode => 1 },
);
is($decoded->[0]{name}, 'Alice',
  'auto_decode: string scalar has quotes stripped');
is($decoded->[0]{age}, 30,
  'auto_decode: integer scalar comes back as Perl number');

# --- auto_decode: vertex object decoded into hashref ---
my $vertex_rows = $schema->storage->cypher(
  $graph,
  q[ MATCH (p:Person {name: $name}) RETURN p ],
  ['p'],
  { name => 'Alice' },
  { auto_decode => 1 },
);
my $v = $vertex_rows->[0]{p};
is(ref($v), 'HASH', 'auto_decode: vertex decodes to hashref');
is($v->{label}, 'Person', 'auto_decode: vertex label preserved');
is_deeply(
  { name => 'Alice', age => 30 },
  $v->{properties},
  'auto_decode: vertex properties decoded into nested hashref'
);

# --- backward-compat: cypher() without auto_decode still returns strings ---
my $raw = $schema->storage->cypher(
  $graph,
  q[ MATCH (p:Person {name: $name}) RETURN p.age ],
  ['age'],
  { name => 'Alice' },
);
like($raw->[0]{age}, qr/^"?30"?$/,
  'cypher() without auto_decode still returns agtype strings');

# --- drop_graph (without cascade should fail if non-empty, in newer AGE) ---
# Skip the non-cascade case — depends on AGE version. Just drop with cascade.
lives_ok { $schema->storage->drop_graph($graph, 1) } 'drop_graph cascade lives';

my ($still_there) = $schema->storage->dbh->selectrow_array(
  'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?',
  undef, $graph,
);
ok(!$still_there, 'graph removed from ag_catalog.ag_graph');

done_testing;
