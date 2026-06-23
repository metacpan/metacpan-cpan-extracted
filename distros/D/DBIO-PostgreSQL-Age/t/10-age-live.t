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

# --- drop_graph (without cascade should fail if non-empty, in newer AGE) ---
# Skip the non-cascade case — depends on AGE version. Just drop with cascade.
lives_ok { $schema->storage->drop_graph($graph, 1) } 'drop_graph cascade lives';

my ($still_there) = $schema->storage->dbh->selectrow_array(
  'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?',
  undef, $graph,
);
ok(!$still_there, 'graph removed from ag_catalog.ag_graph');

done_testing;
