use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr k12, point 3 of the card (maintainer decision 2026-10-09, option a),
# carried over to the extension list of ADR 0066 (karr k20):
# an UNRESTRICTED DBIO::PostgreSQL deploy (no pg_schemas) beside AGE and a
# graph made by create_graph must not drop the graph. create_graph's schema,
# label tables, sequences and _age_cache_invalidate triggers have no pg_depend
# row to the extension, so the extension-member filter of DBIO::PostgreSQL does
# not hide them; DBIO::PostgreSQL::Age::Extension reads ag_catalog.ag_graph
# (inspect) and claims their schemas, and the driver takes them out of the model.
#
# Two halves. The first needs no driver support and always runs against the real
# server: inspect reads the real graph, the claim names a schema that the
# driver's own introspection really holds (so the claim is aimed at something).
# The second -- the unrestricted diff of a schema that declares
# pg_extensions('age') -- runs the protocol inside DBIO::PostgreSQL::Deploy and
# is skipped, loudly, until the driver resolves the list (ADR 0066 section 3,
# dbio-postgresql); it is NOT passing today.
#
# The assertions are about the intent -- the graph and its data survive diff and
# apply -- not about the shape of the model alone.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Deploy; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
my $probe = LiveServer->control_dbh;
my ($age_available) = $probe->selectrow_array(
  q{SELECT 1 FROM pg_available_extensions WHERE name = 'age'});
$probe->disconnect;
plan skip_all => 'Apache AGE extension not available in this PostgreSQL'
  unless $age_available;

use_ok('DBIO::PostgreSQL::Age::Extension');
use DBIO::PostgreSQL::Introspect;

my $GRAPH = 'k12_model';

{
  package K12::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age');
  # no pg_schemas: unrestricted
}

# The shared test database may hold other extensions (postgis, vector, ...).
# An unrestricted deploy drops the extensions it does not declare, which is
# not what this file is about -- declare what is there, plus age.
{
  my $c = LiveServer->dbh_or_die;
  my %ext = map { $_ => 1 } @{ $c->selectcol_arrayref(
    q{SELECT extname FROM pg_extension WHERE extname <> 'plpgsql'}) };
  $ext{age} = 1;
  $c->disconnect;
  K12::Schema->pg_extensions(sort keys %ext);
}

my $schema = K12::Schema->connect($dsn, $user, $pass, {
  AutoCommit => 1, RaiseError => 1, PrintError => 0,
  on_connect_call => 'load_age',
});
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

sub graph_exists {
  my ($hit) = $dbh->selectrow_array(
    'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?', undef, $GRAPH);
  return $hit ? 1 : 0;
}
sub schema_exists {
  my ($hit) = $dbh->selectrow_array(
    'SELECT 1 FROM pg_namespace WHERE nspname = ?', undef, $GRAPH);
  return $hit ? 1 : 0;
}

$dbh->do('SET client_min_messages = warning');
$dbh->do('CREATE EXTENSION IF NOT EXISTS age');
$storage->drop_graph($GRAPH, 1) if graph_exists();
$storage->create_graph($GRAPH);
END { eval { $storage->drop_graph($GRAPH, 1) if $storage && graph_exists() } }

$storage->cypher($GRAPH,
  q{CREATE (:Person {name: 'Alice'})-[:KNOWS]->(:Person {name: 'Bob'}) RETURN 1},
  ['ok']);

sub person_count {
  my $r = $storage->cypher($GRAPH, q{MATCH (p:Person) RETURN count(p)}, ['n']);
  return $r->[0]{n};
}
is(person_count(), 2, 'fixture: two vertices in the graph');

# --- half one: the extension against the real server ------------------------

my $AGE = 'DBIO::PostgreSQL::Age::Extension';
my $state = $AGE->inspect({ dbh => $dbh });
is_deeply [ grep { $_->{name} eq $GRAPH } @{ $state->{graphs} } ],
  [ { name => $GRAPH, namespace => $GRAPH } ],
  'inspect reads the graph and its schema from ag_catalog.ag_graph';
is_deeply [ grep { $_->[1] eq $GRAPH } @{ $AGE->claims({}, { self => { state => $state } }) } ],
  [ [ schema => $GRAPH ] ],
  'claims the graph schema';

my $base = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => [$GRAPH])->model;
ok exists $base->{schemas}{$GRAPH}, 'the driver\'s own model holds the graph schema (the claim has an aim)';
ok scalar(grep { /^\Q$GRAPH\E\./ } keys %{ $base->{tables} }),
  '... with its label tables, which the driver\'s cascade has to take with the schema';

# --- half two: the unrestricted diff of the driver ---------------------------

SKIP: {
  skip 'SKIPPED, NOT PASSING: DBIO::PostgreSQL::Deploy does not run the extension '
     . 'list yet (ADR 0066, dbio-postgresql); the unrestricted diff of a schema '
     . 'declaring pg_extensions(\'age\') cannot be exercised before the driver '
     . 'resolves it', 10
    unless DBIO::PostgreSQL::Deploy->can('_apply_extension_claims')
    != DBIO::Deploy::Base->can('_apply_extension_claims');

my $deploy = $schema->storage->dbio_deploy_class->new(schema => $schema);
my $diff;
lives_ok { $diff = $deploy->diff } 'unrestricted diff lives';

# --- the intent: no operation touches the graph ---------------------------

my $sql = join "\n", map { $_->as_sql } @{ $diff->operations };
unlike $sql, qr/\b\Q$GRAPH\E\b/,
  'no operation of the diff mentions the graph schema'
  or diag $sql;
unlike $sql, qr/_age_cache_invalidate|"?KNOWS"?|"?Person"?/,
  'no operation mentions a label table or the cache trigger'
  or diag $sql;
is(
  scalar(grep { ($_->action // '') eq 'drop' } @{ $diff->operations }), 0,
  'the diff drops nothing')
  or diag $sql;

# --- the model no longer holds the graph -----------------------------------

ok !exists $diff->source->{schemas}{$GRAPH}, 'the graph schema is not a plain schema of the model';
ok !(grep { /^\Q$GRAPH\E\./ } keys %{ $diff->source->{tables} }),
  'no label table in the tables section';
ok !exists $diff->target->{schemas}{$GRAPH},
  'the target (temporary database) holds no graph, so nothing could create it either';

# --- apply: the graph survives ---------------------------------------------

SKIP: {
  skip 'the database holds objects foreign to this test; apply of an '
     . 'unrestricted diff would drop them -- not run against shared content', 2
    if $diff->has_changes;
  lives_ok { $deploy->apply($diff) } 'apply lives';
  ok graph_exists() && schema_exists() && person_count() == 2,
    'the graph, its schema and its data are still there after apply';
}

if ($diff->has_changes) {
  diag 'diff is not empty because of foreign objects in the database, '
     . 'apply not run:';
  diag $sql;
}

# --- the second diff is as quiet as the first -------------------------------

my $again = $deploy->diff;
is(
  scalar(grep { ($_->action // '') eq 'drop' } @{ $again->operations }), 0,
  'a second diff still drops nothing');

}   # SKIP: the driver runs the list

ok graph_exists(), 'the graph is registered in ag_graph at the end';

done_testing;
