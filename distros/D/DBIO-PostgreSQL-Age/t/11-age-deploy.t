use strict;
use warnings;
use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Storage; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';

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

# Schema bootstrap
{
  package TestAgeDeploySchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::Age');
}

my $schema = TestAgeDeploySchema->connect(
  $dsn, $user, $pass,
  {
    AutoCommit      => 1,
    RaiseError      => 1,
    PrintError      => 0,
    on_connect_call => 'load_age',
  },
);

isa_ok($schema->storage, 'DBIO::PostgreSQL::Age::Storage', 'storage class');

# Make sure AGE is enabled in this database.
$schema->storage->dbh->do('CREATE EXTENSION IF NOT EXISTS age');

# --- The "deploy fixture" closure ---------------------------------------------
# An AGE deployment is not a relational DDL diff. The equivalent for a graph
# application is: create_graph (if missing) + idempotent MERGE of seed vertices
# and edges. We package that as a closure so the test can call it once, then
# call it again to prove the operation is idempotent (the whole point of
# "deploy").
sub _graph_exists {
  my ($s, $name) = @_;
  my ($hit) = $s->dbh->selectrow_array(
    'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?', undef, $name,
  );
  return $hit ? 1 : 0;
}

my $deploy_fixtures = sub {
  my $s = $schema->storage;
  $s->create_graph('deploy_test') unless _graph_exists($s, 'deploy_test');

  # Persons — MERGE makes this idempotent.
  for my $p (
    { name => 'Alice', age => 30, role => 'admin'  },
    { name => 'Bob',   age => 25, role => 'member' },
    { name => 'Carol', age => 28, role => 'member' },
  ) {
    $s->cypher(
      'deploy_test',
      q{
        MERGE (p:Person {name: $name})
        SET p.age  = $age,
            p.role = $role
        RETURN 1
      },
      ['ok'],
      $p,
    );
  }

  # Edges — also MERGE on (start, type, end).
  for my $e (
    { from => 'Alice', to => 'Bob',   since => 2020 },
    { from => 'Alice', to => 'Carol', since => 2019 },
    { from => 'Bob',   to => 'Carol', since => 2021 },
  ) {
    $s->cypher(
      'deploy_test',
      q{
        MATCH (a:Person {name: $from}), (b:Person {name: $to})
        MERGE (a)-[r:KNOWS]->(b)
        SET r.since = $since
        RETURN 1
      },
      ['ok'],
      $e,
    );
  }
};

END {
  return unless $schema && $schema->storage;
  eval { $schema->storage->drop_graph('deploy_test', 1) };
}

# --- Deploy once -------------------------------------------------------------
subtest 'first deploy seeds the graph' => sub {
  $deploy_fixtures->();

  my $persons = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH (p:Person) RETURN p.name ORDER BY p.name ],
    ['name'],
  );
  is(scalar @$persons, 3, 'three persons after first deploy');

  my $edges = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH ()-[r:KNOWS]->() RETURN count(r) AS n ],
    ['n'],
  );
  like($edges->[0]{n}, qr/3/, 'three KNOWS edges after first deploy');
};

# --- Deploy again: must be idempotent ---------------------------------------
subtest 'second deploy is idempotent' => sub {
  $deploy_fixtures->();

  my $persons = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH (p:Person) RETURN p.name ORDER BY p.name ],
    ['name'],
  );
  is(scalar @$persons, 3,
    'still three persons after second deploy (no duplicates)');

  my $edges = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH ()-[r:KNOWS]->() RETURN count(r) AS n ],
    ['n'],
  );
  like($edges->[0]{n}, qr/3/,
    'still three KNOWS edges after second deploy (no duplicates)');

  # Properties updated by SET during deploy survive.
  my $alice = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH (p:Person {name: 'Alice'}) RETURN p.age, p.role ],
    [qw(age role)],
    undef,
    { auto_decode => 1 },
  );
  is($alice->[0]{age},  30,    'Alice age unchanged after second deploy');
  is($alice->[0]{role}, 'admin', 'Alice role unchanged after second deploy');
};

# --- auto_decode round-trip in deploy context -------------------------------
subtest 'auto_decode works on a deployed graph' => sub {
  my $rows = $schema->storage->cypher(
    'deploy_test',
    q[ MATCH (p:Person {name: $name})-[:KNOWS]->(friend) RETURN friend.name, friend.age ],
    [qw(name age)],
    { name => 'Alice' },
    { auto_decode => 1 },
  );
  is(scalar @$rows, 2, 'Alice has two outgoing KNOWS edges');
  my @friends = sort map { $_->{name} } @$rows;
  is_deeply(\@friends, [qw(Bob Carol)],
    'auto_decode returns friend names as decoded strings');
};

done_testing;