use strict;
use warnings;
use Test::More;

# Live write-back of a geometry that was read from the database (karr k14).
#
# A value read from a geometry/geography column is inflated from the EWKB
# hex PostGIS sends. Handing that object to another row -- create() with it,
# or $row->geom($other->geom); $row->update -- has to store the very same
# geometry: same type, same dimension (M stays M, 2D stays 2D), same
# doubles bit for bit. The deflater therefore sends the EWKB hex the object
# carries, and both a geometry and a geography column have to take that
# bound hex string on INSERT and on UPDATE.
#
# Beside it: the WKT such an object builds for itself has to be read by the
# server as the geometry it came from (the spatial resultset helpers bind the
# hex since karr k22; t/38-helper-hex-live.t).
#
# The source rows are written with plain SQL, so they owe nothing to the
# code under test; every comparison is made by the server.
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
  package My::WriteBack::Schema::Result::Shape;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_writeback');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry',  is_nullable => 1 },
    geog => { data_type => 'geography', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package My::WriteBack::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Shape => 'My::WriteBack::Schema::Result::Shape');
}

my $schema = My::WriteBack::Schema->connect(sub { $dbh });

# Untyped columns: they take every geometry type and dimension, which a
# geometry(Point,4326) column would not.
eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_writeback') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_writeback (
  id   serial primary key,
  name text,
  geom geometry,
  geog geography
)
SQL

END { eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_writeback') } if $dbh }

my $rs = $schema->resultset('Shape');
my $G  = 'DBIO::PostgreSQL::PostGIS::Geometry';

# Is row $copy the same as row $src, byte for byte, in both columns?
my $compare = sub {
  my ($src_id, $copy_id) = @_;
  return $dbh->selectrow_array(<<'SQL', undef, $src_id, $copy_id);
SELECT ST_AsEWKB(s.geom) = ST_AsEWKB(c.geom),
       ST_AsEWKB(s.geog::geometry) = ST_AsEWKB(c.geog::geometry),
       ST_AsEWKT(c.geom),
       ST_AsEWKT(c.geog)
  FROM dbio_postgis_test_writeback s, dbio_postgis_test_writeback c
 WHERE s.id = ? AND c.id = ?
SQL
};

my $is_copy = sub {
  my ($src_id, $copy_id, $ewkt, $how) = @_;
  my ($geom_same, $geog_same, $geom_ewkt, $geog_ewkt)
    = $compare->($src_id, $copy_id);
  ok $geom_same, "$how: geometry column holds the same EWKB";
  ok $geog_same, "$how: geography column holds the same EWKB";
  is $geom_ewkt, $ewkt, "$how: geometry column, as the server prints it";
  is $geog_ewkt, $ewkt, "$how: geography column, as the server prints it";
};

# EWKT in the form ST_AsEWKT prints it (M is "POINTM", Z goes unmarked).
my @shapes = (
  [ 'line of three points'       => 'SRID=4326;LINESTRING(0 0,1 1,2 2)' ],
  [ 'multipoint of three points' => 'SRID=4326;MULTIPOINT(1 2,3 4,5 6)' ],
  [ 'polygon of three rings'     =>
    'SRID=4326;POLYGON((0 0,9 0,9 9,0 0),(3 1,4 1,4 2,3 1),(6 2,7 2,7 3,6 2))' ],
  [ 'point M'                    => 'SRID=4326;POINTM(1 2 9)' ],
  [ 'point ZM'                   => 'SRID=4326;POINT(1 2 3 4)' ],
  [ '3D line of two points'      => 'SRID=4326;LINESTRING(0 0 5,1 1 6)' ],
);

for my $shape (@shapes) {
  my ($name, $ewkt) = @$shape;

  subtest "write back a read geometry: $name" => sub {
    my ($src_id) = $dbh->selectrow_array(<<'SQL', undef, $name, $ewkt, $ewkt);
INSERT INTO dbio_postgis_test_writeback (name, geom, geog)
VALUES (?, ?::geometry, ?::geography)
RETURNING id
SQL
    my $src = $rs->find($src_id);
    isa_ok $src->geom, $G, 'geometry column inflates';
    isa_ok $src->geog, $G, 'geography column inflates';
    ok $src->geom->ewkb_hex, 'the read geometry carries its EWKB hex';

    # The WKT the object builds for itself is what the resultset helpers
    # bind (ST_GeomFromText). The server has to read it as this geometry.
    my ($understood) = eval {
      $dbh->selectrow_array(<<'SQL', undef, $src->geom->ewkt, $src_id);
SELECT ST_AsEWKB(ST_GeomFromEWKT(?)) = ST_AsEWKB(geom)
  FROM dbio_postgis_test_writeback WHERE id = ?
SQL
    };
    ok $understood, 'the server reads the built EWKT as the same geometry'
      or diag "ewkt: " . ($src->geom->ewkt // 'undef') . ($@ ? "\n$@" : '');

    my $found = eval { $rs->intersects(geom => $src->geom)->count };
    ok $found, 'a read geometry works as the argument of a spatial helper'
      or diag $@;

    # INSERT with the read objects
    my $created = eval {
      $rs->create({
        name => "$name (create)",
        geom => $src->geom,
        geog => $src->geog,
      });
    };
    ok $created, 'create with the read geometry' or diag $@;
    $is_copy->($src_id, $created->id, $ewkt, 'create') if $created;

    # UPDATE of a row that held something else
    my $origin = $G->point(0, 0, srid => 4326);
    my $target = $rs->create({
      name => "$name (update)",
      geom => $origin,
      geog => $origin,
    });
    $target->geom($src->geom);
    $target->geog($src->geog);
    ok eval { $target->update; 1 }, 'update with the read geometry'
      or diag $@;
    $is_copy->($src_id, $target->id, $ewkt, 'update');

    # Written back to where it came from, it is the value already there.
    $src->geom($src->geom);
    ok !$src->is_column_changed('geom'),
      'setting a read geometry on its own row leaves the column clean';
  };
}

# Full double precision. 0.1 + 0.2 is not 0.3, but Perl prints it as 0.3,
# so a WKT built in Perl would store a different number.
subtest 'a double survives the write-back bit for bit' => sub {
  my $x = 0.1 + 0.2;
  ok $x != 0.3 && "$x" eq '0.3',
    'the fixture is a double that Perl stringifies to another one';

  my $hex = uc unpack 'H*', pack('C V V d< d<', 1, 0x20000001, 4326, $x, 52.5);
  my $server_hex = sub {
    my ($id) = @_;
    return map { uc } $dbh->selectrow_array(<<'SQL', undef, $id);
SELECT encode(ST_AsEWKB(geom), 'hex'), encode(ST_AsEWKB(geog::geometry), 'hex')
  FROM dbio_postgis_test_writeback WHERE id = ?
SQL
  };

  # An EWKB hex string is passed through by the deflater as it is.
  my $src = $rs->create({ name => 'precise', geom => $hex, geog => $hex });
  is_deeply [ $server_hex->($src->id) ], [ $hex, $hex ],
    'a bound EWKB hex string is stored as it is, geometry and geography';

  my $read = $rs->find($src->id);
  is $read->geom->ewkb_hex, $hex, 'read back: the same hex';

  my $created = $rs->create({
    name => 'precise (create)',
    geom => $read->geom,
    geog => $read->geog,
  });
  is_deeply [ $server_hex->($created->id) ], [ $hex, $hex ],
    'create with the read geometry stores the same bits';

  my $origin = $G->point(0, 0, srid => 4326);
  my $target = $rs->create({
    name => 'precise (update)', geom => $origin, geog => $origin,
  });
  $target->geom($read->geom);
  $target->geog($read->geog);
  $target->update;
  is_deeply [ $server_hex->($target->id) ], [ $hex, $hex ],
    'update with the read geometry stores the same bits';
};

# An object that never came from the database has no hex and is written as
# EWKT, as before.
subtest 'a geometry built in Perl is still written as EWKT' => sub {
  my $line = $G->linestring([[0,0],[1,1],[2,2]], srid => 4326);
  is $line->ewkb_hex, undef, 'no hex on a built geometry';
  my $row = $rs->create({ name => 'built', geom => $line, geog => $line });
  my ($geom, $geog) = $dbh->selectrow_array(<<'SQL', undef, $row->id);
SELECT ST_AsEWKT(geom), ST_AsEWKT(geog)
  FROM dbio_postgis_test_writeback WHERE id = ?
SQL
  is $geom, 'SRID=4326;LINESTRING(0 0,1 1,2 2)', 'geometry column';
  is $geog, 'SRID=4326;LINESTRING(0 0,1 1,2 2)', 'geography column';
};

done_testing;
