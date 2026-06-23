use strict;
use warnings;
use Test::More;

# Live PostGIS round-trip. Gated on DBIO_TEST_PG_DSN, skips quietly when no
# DSN is configured or the target database refuses CREATE EXTENSION postgis.

my $dsn = $ENV{DBIO_TEST_PG_DSN} // $ENV{DBIO_TEST_PG_EXT_DSN};
plan skip_all => 'DBIO_TEST_PG_DSN not set' unless $dsn;

eval { require DBI; require DBD::Pg; 1 }
  or plan skip_all => 'DBI / DBD::Pg not available';

my $user = $ENV{DBIO_TEST_PG_USER} // $ENV{DBIO_TEST_PG_EXT_USER};
my $pass = $ENV{DBIO_TEST_PG_PASS} // $ENV{DBIO_TEST_PG_EXT_PASS};

my $dbh = eval {
  DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
};
plan skip_all => "Cannot connect: $@" unless $dbh;

eval { $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis') };
plan skip_all => "PostGIS extension not available: $@" if $@;

{
  package My::Live::Schema::Result::Place;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_place');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', srid => 4326 },
  );
  __PACKAGE__->set_primary_key('id');

  package My::Live::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Place => 'My::Live::Schema::Result::Place');
}

my $schema = My::Live::Schema->connect(sub { $dbh });

eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_place') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_place (
  id   serial primary key,
  name text,
  geom geometry(Point, 4326)
)
SQL

my $rs = $schema->resultset('Place');

isa_ok $rs, 'DBIO::PostgreSQL::PostGIS::ResultSet',
  'resultset auto-promoted on a real connection';

my $brandenburg = DBIO::PostgreSQL::PostGIS::Geometry->point(13.4, 52.5, srid => 4326);
my $row = $rs->create({ name => 'Brandenburger Tor', geom => $brandenburg });
ok $row->id, 'inserted with id';

my $loaded = $rs->find($row->id);
isa_ok $loaded->geom, 'DBIO::PostgreSQL::PostGIS::Geometry', 'inflated on read';
is $loaded->geom->srid, 4326;
is $loaded->geom->wkt, 'POINT(13.4 52.5)';

# spatial query
my $here = DBIO::PostgreSQL::PostGIS::Geometry->point(13.4, 52.5, srid => 4326);
my $near = $rs->within_distance(geom => $here, 0.001)->count;
is $near, 1, 'within_distance finds the row';

my $far = $rs->within_distance(
  geom => DBIO::PostgreSQL::PostGIS::Geometry->point(0, 0, srid => 4326),
  0.0001,
)->count;
is $far, 0, 'within_distance excludes far rows';

# nearest_to KNN
my @ordered = $rs->nearest_to(geom => $here)->all;
ok @ordered, 'nearest_to returns rows';

$dbh->do('DROP TABLE dbio_postgis_test_place');
done_testing;
