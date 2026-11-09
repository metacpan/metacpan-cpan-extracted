use strict;
use warnings;
use Test::More;
use JSON::PP ();

# Live read of empty geometries (karr k19) and of GEOMETRYCOLLECTIONs
# (karr k24).
#
# An empty geometry read from the database used to say it was not empty
# and to be "LINESTRING()" or "POINT(NaN NaN)"; a collection lost the types
# of its members and was "GEOMETRYCOLLECTION()". Rows are written with
# plain SQL (ST_GeomFromText), read through the inflater, and then held
# against what the server says about the same row:
#
#  - is_empty against ST_IsEmpty;
#  - wkt against ST_AsText, where the two print the same text (they do not
#    for MULTIPOINT, which PostGIS prints with a parenthesis around every
#    point, and the dimension marker is told apart by the space the server
#    puts before the parenthesis);
#  - the WKT and EWKT the object builds are read by the server as the very
#    geometry the row holds, bit for bit (ST_AsEWKB), which is what makes
#    them usable as the argument of a spatial helper;
#  - to_geojson against ST_AsGeoJSON, where the server prints all of it;
#  - bbox against ST_XMin ... ST_YMax;
#  - the object written to another row stores the same EWKB.
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
  package My::EmptyColl::Schema::Result::Shape;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_empty_coll');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package My::EmptyColl::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Shape => 'My::EmptyColl::Schema::Result::Shape');
}

my $schema = My::EmptyColl::Schema->connect(sub { $dbh });

# An untyped column: it takes every geometry type and dimension.
eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_empty_coll') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_empty_coll (
  id   serial primary key,
  name text,
  geom geometry
)
SQL

END { eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_empty_coll') } if $dbh }

my $rs = $schema->resultset('Shape');
my $G  = 'DBIO::PostgreSQL::PostGIS::Geometry';

# [ the WKT written, text, geojson ]
#  text:    the object's wkt is ST_AsText with the space before "(" removed
#  geojson: to_geojson is what ST_AsGeoJSON prints. Not for what the server
#           does differently: an M ordinate (it leaves it out), an empty
#           member other than a 2D point (it drops it, and the only empty point
#           of a multipoint with it), a collection in a
#           collection (it refuses to print one).
my @cases = (
  [ 'POINT EMPTY',                 1, 1 ],
  [ 'POINT Z EMPTY',               1, 1 ],
  [ 'POINT M EMPTY',               1, 1 ],
  [ 'LINESTRING EMPTY',            1, 1 ],
  [ 'LINESTRING ZM EMPTY',         1, 1 ],
  [ 'POLYGON EMPTY',               1, 1 ],
  [ 'MULTIPOINT EMPTY',            1, 1 ],
  [ 'MULTILINESTRING EMPTY',       1, 1 ],
  [ 'MULTIPOLYGON EMPTY',          1, 1 ],
  [ 'GEOMETRYCOLLECTION EMPTY',    1, 1 ],
  [ 'GEOMETRYCOLLECTION Z EMPTY',  1, 1 ],
  # empty parts
  [ 'MULTIPOINT(EMPTY,(1 2))',     0, 1 ],
  [ 'MULTIPOINT((1 2),EMPTY)',     0, 1 ],
  [ 'MULTIPOINT(EMPTY)',           0, 0 ],   # the server prints coordinates [] here
  [ 'MULTILINESTRING(EMPTY,(0 0,1 1))', 1, 1 ],
  [ 'MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))', 1, 1 ],
  # collections
  [ 'GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 1, 1 ],
  [ 'GEOMETRYCOLLECTION Z(POINT Z(1 2 3),LINESTRING Z(0 0 1,1 1 2))', 1, 1 ],
  [ 'GEOMETRYCOLLECTION M(POINT M(1 2 3))', 1, 0 ],
  [ 'GEOMETRYCOLLECTION ZM(POINT ZM(1 2 3 4))', 1, 0 ],
  [ 'GEOMETRYCOLLECTION(MULTIPOINT((1 2),(3 4)),POLYGON((0 0,1 0,1 1,0 0)))', 0, 1 ],
  [ 'GEOMETRYCOLLECTION(MULTILINESTRING((0 0,1 1),(2 2,3 3)),MULTIPOLYGON(((0 0,1 0,1 1,0 0))))', 1, 1 ],
  [ 'GEOMETRYCOLLECTION(POINT EMPTY,LINESTRING(0 0,1 1))', 1, 1 ],
  [ 'GEOMETRYCOLLECTION(POINT Z EMPTY)', 1, 0 ],
  [ 'GEOMETRYCOLLECTION(POLYGON EMPTY)', 1, 0 ],
  [ 'GEOMETRYCOLLECTION(POINT EMPTY,POLYGON EMPTY)', 1, 0 ],
  [ 'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))', 1, 0 ],
);

my $json = JSON::PP->new;

for my $case (@cases) {
  my ($wkt, $text, $geojson) = @$case;

  subtest "read $wkt" => sub {
    my ($id) = $dbh->selectrow_array(
      'INSERT INTO dbio_postgis_test_empty_coll (name, geom) '
      . 'VALUES (?, ST_GeomFromText(?, 4326)) RETURNING id', undef, $wkt, $wkt);

    my $src = $rs->find($id);
    my $g   = $src->geom;
    isa_ok $g, $G, 'the column inflates' or return;

    my ($as_text, $is_empty, $xmin, $ymin, $xmax, $ymax) = $dbh->selectrow_array(<<'SQL', undef, $id);
SELECT ST_AsText(geom), ST_IsEmpty(geom),
       ST_XMin(geom), ST_YMin(geom), ST_XMax(geom), ST_YMax(geom)
  FROM dbio_postgis_test_empty_coll WHERE id = ?
SQL

    is $g->is_empty ? 1 : 0, $is_empty ? 1 : 0, 'is_empty is what ST_IsEmpty says';

    if ($text) {
      (my $want = $as_text) =~ s/ \(/(/g;
      is $g->wkt, $want, 'wkt is what ST_AsText prints';
    }
    ok defined $g->wkt, 'there is a wkt';
    is $g->ewkt, 'SRID=4326;' . $g->wkt, 'ewkt carries the SRID';

    # The built text is read by the server as this very geometry.
    my ($via_wkt, $via_ewkt) = eval {
      $dbh->selectrow_array(<<'SQL', undef, $g->wkt, $g->ewkt, $id);
SELECT ST_AsEWKB(ST_GeomFromText(?, 4326)) = ST_AsEWKB(geom),
       ST_AsEWKB(ST_GeomFromEWKT(?)) = ST_AsEWKB(geom)
  FROM dbio_postgis_test_empty_coll WHERE id = ?
SQL
    };
    diag $@ if $@;
    ok $via_wkt,  'the server reads the built wkt as the same geometry, bit for bit';
    ok $via_ewkt, 'the server reads the built ewkt as the same geometry, bit for bit';

    if ($geojson) {
      my ($as_json) = $dbh->selectrow_array(
        'SELECT ST_AsGeoJSON(geom) FROM dbio_postgis_test_empty_coll WHERE id = ?', undef, $id);
      is_deeply $g->to_geojson, $json->decode($as_json),
        'to_geojson is what ST_AsGeoJSON prints'
        or diag "server: $as_json";
    }

    if ($is_empty) {
      is $g->bbox, undef, 'an empty geometry has no bbox';
    }
    elsif (defined $xmin) {
      is_deeply $g->bbox, [ $xmin, $ymin, $xmax, $ymax ], 'bbox is the extent the server finds';
    }
    else {
      is $g->bbox, undef, 'no extent, no bbox';
    }

    # Written to another row, the same EWKB is stored.
    my $copy = eval { $rs->create({ name => "$wkt (copy)", geom => $g }) };
    ok $copy, 'create with the read geometry' or diag $@ or return;
    my ($same) = $dbh->selectrow_array(<<'SQL', undef, $id, $copy->id);
SELECT ST_AsEWKB(s.geom) = ST_AsEWKB(c.geom)
  FROM dbio_postgis_test_empty_coll s, dbio_postgis_test_empty_coll c
 WHERE s.id = ? AND c.id = ?
SQL
    ok $same, 'the copy holds the same EWKB';
  };
}

done_testing;
