use strict;
use warnings;

use Test::More;
use Test::Exception;

# Live PostGIS deploy round-trip. Verifies that the temp-DB deploy path
# (install -> introspect-live + deploy-temp + introspect-temp -> diff)
# runs through DBIO::PostgreSQL::PostGIS::Introspect, so a geometry column
# with a type/srid modifier deploys and diffs cleanly (no spurious diff,
# no crash from the introspector factory).
#
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable DB.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

BEGIN {
  eval { require Moo; 1 } or plan skip_all => 'Moo not installed';
}

use DBI;
use DBIO::PostgreSQL::PostGIS::Deploy;
use DBIO::PostgreSQL::PostGIS::Introspect;

# --- cheap, DB-free guard: the introspect-class hook -----------------------
is(
  DBIO::PostgreSQL::PostGIS::Deploy->_introspect_class,
  'DBIO::PostgreSQL::PostGIS::Introspect',
  '_introspect_class hook selects the PostGIS introspector',
);

eval { require DBD::Pg; 1 } or plan skip_all => 'DBD::Pg not available';

my $probe = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $probe;

eval { $probe->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;
$probe->disconnect;

my $NS = 'dbio_postgis_deploy_test';

{
  package DeployGisTest::Schema;
  use base 'DBIO::Schema';
  # PostgreSQL supplies pg_schemas/pg_search_path; PostgreSQL::PostGIS
  # (listed last => more-base => its connection() runs last) wins the
  # storage_type race and installs the PostGIS storage class.
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->pg_schemas('dbio_postgis_deploy_test');
  __PACKAGE__->pg_search_path('dbio_postgis_deploy_test', 'public');
  # Declare the extension so install DDL emits CREATE EXTENSION postgis --
  # required so the geometry type exists in the freshly created temp DB.
  __PACKAGE__->pg_extensions('postgis');
}
{
  package DeployGisTest::Schema::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::PostGIS');
  __PACKAGE__->table('dbio_postgis_deploy_test.dbio_postgis_place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry(Point,4326)' },
  );
  __PACKAGE__->set_primary_key('id');
}
DeployGisTest::Schema->register_class(
  Place => 'DeployGisTest::Schema::Result::Place',
);

sub cleanup {
  my $h = DBI->connect($dsn, $user, $pass,
    { RaiseError => 0, PrintError => 0 });
  $h->do("DROP SCHEMA IF EXISTS $NS CASCADE");
  $h->do("CREATE SCHEMA $NS");
  $h->disconnect;
}

cleanup();
END {
  return unless $dsn;
  my $h = DBI->connect($dsn, $user, $pass,
    { RaiseError => 0, PrintError => 0 });
  $h->do("DROP SCHEMA IF EXISTS $NS CASCADE") if $h;
}

my @connect = ($dsn, $user, $pass, {
  on_connect_do => ["SET search_path TO $NS, public"],
});

my $schema = DeployGisTest::Schema->connect(@connect);
$schema->storage->dbh->do("SET search_path TO $NS, public");

# Storage routes to the PostGIS deploy class
is(
  $schema->storage->dbio_deploy_class,
  'DBIO::PostgreSQL::PostGIS::Deploy',
  'storage selects the PostGIS deploy class',
);

my $deploy = $schema->storage->dbio_deploy_class->new(schema => $schema);
isa_ok($deploy, 'DBIO::PostgreSQL::PostGIS::Deploy');

lives_ok { $deploy->install } 'install lives with a geometry column';

my ($exists) = $schema->storage->dbh->selectrow_array(
  q{SELECT 1 FROM information_schema.columns
    WHERE table_schema = ? AND table_name = 'dbio_postgis_place'
      AND column_name = 'geom'},
  undef, $NS,
);
ok($exists, 'geometry column present after install');

# The critical round-trip: diff deploys the model to a temp DB and
# introspects both sides through PostGIS::Introspect. The geometry column
# must NOT show up in the diff -- that proves the geometry(Point,4326)
# modifier survives the round-trip and the introspector factory neither
# crashed nor picked the wrong (non-PostGIS) class.
#
# We assert specifically on our table/column rather than has_changes,
# because a PostGIS-enabled database may carry extra extensions
# (postgis_topology, tiger_geocoder, ...) that the model does not declare;
# that extension noise is unrelated to the geometry round-trip.
subtest 'geometry column round-trips with no spurious diff' => sub {
  my $diff;
  lives_ok { $diff = $deploy->diff } 'diff (temp-db round-trip) lives';
  ok($diff, 'diff object returned');

  my $sql = $diff->as_sql // '';
  unlike($sql, qr/dbio_postgis_place/,
    'no diff operation touches the place table')
    or diag $sql;
  unlike($sql, qr/\bgeom\b/i,
    'no diff operation touches the geometry column')
    or diag $sql;
};

done_testing;
