use strict;
use warnings;
use Test::More;

# Live upsert smoke test -- ADR 0036 support inherited through the PostGIS
# storage layer (follow-up to dbio-postgresql k43, karr k5). This extension
# dist adds no upsert code of its own: the PostGIS layer composes over the
# PostgreSQL driver storage, so the driver's supports_upsert capability must
# survive the composition and a plain upsert must round-trip unchanged.
#
# The extra case pins a geometry column in the update set. The default
# update set writes every non-conflict column through the engine's EXCLUDED
# pseudo-row, so the attempted geometry must travel VALUES -> EXCLUDED ->
# DO UPDATE SET as EWKT without tripping over the PostGIS type.
#
# Gated on DBIO_TEST_PG_DSN; skips quietly without a PostGIS-capable DB.

my ($dsn, $user, $pass) =
  @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};
$dsn  //= $ENV{DBIO_TEST_PG_EXT_DSN};
$user //= $ENV{DBIO_TEST_PG_EXT_USER};
$pass //= $ENV{DBIO_TEST_PG_EXT_PASS};

plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

my $dbh = eval {
  DBI->connect($dsn, $user, $pass,
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

eval { $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

{
  package My::Upsert::Schema::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_upsert');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', srid => 4326 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(dbio_postgis_test_upsert_name_key => ['name']);

  package My::Upsert::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Place => 'My::Upsert::Schema::Result::Place');
}

my $schema = My::Upsert::Schema->connect(sub { $dbh });

eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_upsert') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_upsert (
  id   serial primary key,
  name text NOT NULL UNIQUE,
  geom geometry(Point, 4326)
)
SQL

END { eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_upsert') } }

my $rs = $schema->resultset('Place');

# ---- the capability survives the layer composition -------------------------
# Driver resolution is lazy: touch dbh once, THEN assert the composed
# storage (house rules, ADR 0032 corollary).
my $storage = $schema->storage;
$storage->dbh;

isa_ok $storage, 'DBIO::PostgreSQL::PostGIS::Storage',
  'the live storage carries the PostGIS layer';
isa_ok $storage, 'DBIO::PostgreSQL::Storage',
  '... composed over the PostgreSQL driver storage';
ok $storage->_use_supports_upsert,
  'the composed storage declares supports_upsert (ADR 0036)';

# ---- plain upsert round-trip, geometry in the update set -------------------
my $inserted = $rs->upsert(
  {
    name => 'brandenburg',
    geom => DBIO::PostgreSQL::PostGIS::Geometry->point(13.4, 52.5, srid => 4326),
  },
  { conflict_target => ['name'] },
);

ok $inserted, 'upsert on an empty table returns a row';
ok $inserted->id, '... with an engine-assigned id';
is $rs->count, 1, '... exactly one row exists';

{
  my $row = $rs->find($inserted->id);
  isa_ok $row->geom, 'DBIO::PostgreSQL::PostGIS::Geometry',
    'geometry inflates on the stored row';
  is $row->geom->wkt, 'POINT(13.4 52.5)', '... carrying the inserted geometry';
}

# Second upsert, same name, NEW geometry. The default update set writes the
# geometry through EXCLUDED."geom" -- the attempted value must land, not be
# dropped or mangled on the way through the conflict clause.
my $updated = $rs->upsert(
  {
    name => 'brandenburg',
    geom => DBIO::PostgreSQL::PostGIS::Geometry->point(13.06, 52.4, srid => 4326),
  },
  { conflict_target => ['name'] },
);

is $updated->id, $inserted->id,
  'the second upsert wrote the SAME row -- update, not insert';
is $rs->count, 1, '... no second row appeared';

{
  my $row = $rs->find($inserted->id);
  isa_ok $row->geom, 'DBIO::PostgreSQL::PostGIS::Geometry',
    'geometry survives the EXCLUDED round-trip inflated';
  is $row->geom->wkt, 'POINT(13.06 52.4)',
    '... carrying the NEW attempted value (EXCLUDED."geom")';
}

done_testing;
