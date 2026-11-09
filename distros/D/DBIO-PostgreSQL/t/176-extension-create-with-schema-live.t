use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k141 -- an unqualified CREATE EXTENSION lands in the first schema of the
# session's search_path. The activation of age puts ag_catalog first, so with
# pg_extensions('age', 'postgis') postgis used to be installed into
# ag_catalog and a geometry column failed on public.geometry. Every CREATE
# EXTENSION now names its schema, public where the declaration names none.
#
# Since the decision of 2026-10-24 the schema of a created extension is, in this
# order, the declared one, the one its control file fixes (age: ag_catalog,
# read from the server by the deploy), else public -- so age is written
# without the clause (the server installs it in ag_catalog and refuses WITH
# SCHEMA public) and postgis WITH SCHEMA public. No list of extensions is
# built in.
#
# Needs age and postgis on the server and their DBIO distributions; skipped,
# with the reason, where either is missing. Runs in a database of its own.

for my $module (qw(DBIO::PostgreSQL::Age DBIO::PostgreSQL::PostGIS)) {
  eval "require $module; 1"
    or plan skip_all => "$module not installed (dbio-postgresql-age / dbio-postgresql-postgis)";
}

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions WHERE name IN ('age', 'postgis')}
  ) };
  $h->disconnect;
  plan skip_all => 'extension age not available on the server' unless $avail{age};
  plan skip_all => 'extension postgis not available on the server' unless $avail{postgis};
}

($dsn, $user, $pass) = PrivatePgDatabase->create('pg_k141');

{
  package K141::Result::Place;
  use base 'DBIO::Core';
  # the session has ag_catalog first in its search_path: a table without a
  # schema of its own would be created there (install) and in public (the
  # temporary database of the diff), and the second diff would not be empty
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->pg_schema('public');
  __PACKAGE__->table('k141_place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    geom => { data_type => 'geometry(Point,4326)', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K141::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_extensions('age', 'postgis');
  __PACKAGE__->register_class(Place => 'K141::Result::Place');
}

# The session has the age activation: ag_catalog first in its search_path.
my $schema = K141::Schema->connect($dsn, $user, $pass, {
  AutoCommit => 1, RaiseError => 1, PrintError => 0,
  on_connect_call => 'load_age',
});
my $deploy = $schema->pg_deploy;

my $control = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
sub ext_schema {
  my ($name) = @_;
  return scalar $control->selectrow_array(
    q{SELECT n.nspname FROM pg_catalog.pg_extension e
        JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
       WHERE e.extname = ?}, undef, $name);
}

my $sql = $deploy->diff->as_sql;
like $sql, qr/^CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;$/m,
  'the diff of an empty database names the schema of postgis'
  or diag $sql;

unlike $sql, qr/^CREATE EXTENSION IF NOT EXISTS age WITH SCHEMA/m,
  '... and age, whose control file fixes ag_catalog, is not given public'
  or diag $sql;

lives_ok { $deploy->install } 'install lives, geometry column included';

is ext_schema('postgis'), 'public', 'postgis is installed in public, not in ag_catalog';
is ext_schema('age'), 'ag_catalog', 'age is installed in the schema its control file fixes';

my $again = $deploy->diff;
ok !$again->has_changes, 'a second diff is empty'
  or diag $again->as_sql;

# A declared schema against the one the control file fixes: refused before any
# statement, naming the extension and both schemas.
{
  package K141::Clash;
  use DBIO 'Schema', -pg;
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::Age');
  __PACKAGE__->pg_extensions(age => { schema => 'public' });
}
{
  my $clash = K141::Clash->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
  throws_ok { $clash->pg_deploy->diff } qr/extension age is declared in schema public, but its control file fixes schema ag_catalog/,
    'a declared schema other than the fixed one is refused by the diff';
  throws_ok { $clash->pg_deploy->install } qr/extension age is declared in schema public, but its control file fixes schema ag_catalog/,
    '... and by the install';
  $clash->storage->disconnect;
}

$schema->storage->disconnect;
$control->disconnect;

done_testing;
