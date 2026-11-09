use strict;
use warnings;
use Test::More;
use Test::Exception;

# karr k12, carried over to ADR 0066 (karr k20): AGE, PostGIS and
# DBIO::PostgreSQL stacked on ONE schema through the extension list
# (pg_extensions('age', 'postgis')), for an unrestricted deploy (no
# pg_schemas). Both things hold at once, in either declaration order:
#
#   * the graph made by create_graph is claimed by Age::Extension, so it is
#     known to the model and survives diff and apply, and
#   * geometry columns carry the annotation of PostGIS::Extension, so a second
#     diff after the deploy is empty.
#
# This needs the driver to run the list (ADR 0066 section 3, dbio-postgresql)
# and the PostGIS distribution to ship its extension class; until then the
# file is skipped as a whole, with the reason -- it is not passing. The offline
# commutativity assertion of the pair is t/50-extension-set.t.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn && $user;

eval { require DBIO::PostgreSQL::Deploy; 1 }
  or plan skip_all => 'DBIO::PostgreSQL not installed';
eval { require DBIO::PostgreSQL::PostGIS; require DBIO::PostgreSQL::PostGIS::Extension; 1 }
  or plan skip_all => 'DBIO::PostgreSQL::PostGIS::Extension not available (dbio-postgresql-postgis, ADR 0066)';
plan skip_all => 'SKIPPED, NOT PASSING: DBIO::PostgreSQL::Deploy does not run the '
  . 'extension list yet (ADR 0066, dbio-postgresql; its deploy has no _apply_extension_claims of its own)'
  unless DBIO::PostgreSQL::Deploy->can('_apply_extension_claims')
    != DBIO::Deploy::Base->can('_apply_extension_claims');

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
my $probe = LiveServer->control_dbh;
my %avail = map { $_ => 1 } @{ $probe->selectcol_arrayref(
  q{SELECT name FROM pg_available_extensions WHERE name IN ('age','postgis')}) };
$probe->disconnect;
plan skip_all => 'Apache AGE extension not available in this PostgreSQL'
  unless $avail{age};
plan skip_all => 'PostGIS extension not available in this PostgreSQL'
  unless $avail{postgis};

my $GRAPH = 'k12_chain';
my $TABLE = 'k12_chain_place';

{
  package K12C::Place;
  use base 'DBIO::Core';
  __PACKAGE__->table('k12_chain_place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_nullable => 0 },
    name => { data_type => 'text',    is_nullable => 1 },
    geom => { data_type => 'geometry(Point,4326)', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K12C::Base;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age', 'PostgreSQL::PostGIS');

  package K12C::Changed;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Place => 'K12C::Place');
}

# The shared test database may hold other extensions (vector, ...). An
# unrestricted deploy drops the ones it does not declare; declare what is
# there, plus age and postgis.
{
  my $c = LiveServer->dbh_or_die;
  my %ext = map { $_ => 1 } @{ $c->selectcol_arrayref(
    q{SELECT extname FROM pg_extension WHERE extname <> 'plpgsql'}) };
  @ext{qw(age postgis)} = (1, 1);
  $c->disconnect;
  $_->pg_extensions(sort keys %ext) for qw(K12C::Base K12C::Changed);
}

my %opt = (
  AutoCommit => 1, RaiseError => 1, PrintError => 0,
  on_connect_call => 'load_age',
);
my $base    = K12C::Base->connect($dsn, $user, $pass, {%opt});
my $changed = K12C::Changed->connect($dsn, $user, $pass, {%opt});
my $storage = $base->storage;
my $dbh     = $storage->dbh;

sub graph_exists {
  my ($hit) = $dbh->selectrow_array(
    'SELECT 1 FROM ag_catalog.ag_graph WHERE name = ?', undef, $GRAPH);
  return $hit ? 1 : 0;
}
sub table_exists {
  my ($hit) = $dbh->selectrow_array(
    q{SELECT to_regclass(?)}, undef, "public.$TABLE");
  return defined $hit ? 1 : 0;
}

END {
  eval {
    if ($dbh) {
      $dbh->do(qq{DROP TABLE IF EXISTS public.$TABLE});
      $storage->drop_graph($GRAPH, 1) if graph_exists();
    }
  };
}

$dbh->do('SET client_min_messages = warning');
$dbh->do('CREATE EXTENSION IF NOT EXISTS age');
# age puts ag_catalog first in the search_path; without WITH SCHEMA postgis
# would be installed there instead of public.
$dbh->do('CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public');
$dbh->do(qq{DROP TABLE IF EXISTS public.$TABLE});
$storage->drop_graph($GRAPH, 1) if graph_exists();
$storage->create_graph($GRAPH);
$storage->cypher($GRAPH,
  q{CREATE (:Person {name: 'Alice'})-[:KNOWS]->(:Person {name: 'Bob'}) RETURN 1},
  ['ok']);

sub person_count {
  my $r = $storage->cypher($GRAPH, q{MATCH (p:Person) RETURN count(p)}, ['n']);
  return $r->[0]{n};
}
is person_count(), 2, 'fixture: two vertices in the graph';

# --- the driver's deploy class (no chain: one owner) -------------------------

my $class = $storage->dbio_deploy_class;
is $class, 'DBIO::PostgreSQL::Deploy', 'dbio_deploy_class is the driver\'s';

# --- diff: nothing, and the graph is known ----------------------------------

my $deploy = $class->new(schema => $base);
my $diff;
lives_ok { $diff = $deploy->diff } 'unrestricted diff lives (no pg_schemas)';
my $sql = join "\n", map { $_->as_sql } @{ $diff->operations };
ok !$diff->has_changes, 'the diff is empty'
  or diag $sql;
ok !exists $diff->source->{schemas}{$GRAPH}, 'the graph schema is no plain schema';
ok graph_exists() && person_count() == 2, 'the graph is still there after the diff';

# --- apply with a change: create a table with a geometry column --------------

my $cdeploy = $class->new(schema => $changed);
my $cdiff   = $cdeploy->diff;
my $csql    = join "\n", map { $_->as_sql } @{ $cdiff->operations };
ok $cdiff->has_changes, 'a declared table is a change';
like $csql, qr/CREATE TABLE[^;]*\Q$TABLE\E/i, 'the change creates the table'
  or diag $csql;
unlike $csql, qr/\bDROP\b|\b\Q$GRAPH\E\b/i,
  'nothing is dropped and the graph is not mentioned'
  or diag $csql;

lives_ok { $cdeploy->apply($cdiff) } 'apply lives';
ok table_exists(), 'the table was created';
ok graph_exists() && person_count() == 2,
  'the graph, its data and its registration survive the apply';

my $again = $cdeploy->diff;
ok !$again->has_changes, 'the diff after apply is empty (geometry metadata read)'
  or diag join "\n", map { $_->as_sql } @{ $again->operations };

done_testing;
