use strict;
use warnings;
use Test::More;

# Live read and write-back of geometries the EWKB decoder does not decode
# (karr k15).
#
# A column of type geometry takes CIRCULARSTRING, COMPOUNDCURVE,
# CURVEPOLYGON, MULTICURVE, MULTISURFACE, POLYHEDRALSURFACE, TIN and
# TRIANGLE; this distribution decodes none of them. Such a row used to
# read as undef -- the same as a row that holds NULL -- and nothing of it
# could be written anywhere else. It has to read as an object that says
# what it is (type and SRID, off the EWKB header) and carries the hex,
# and writing that object to another row has to store the same geometry.
# A row that does hold NULL still reads as undef: telling the two apart is
# the point.
#
# The type name is compared with the server's own GeometryType(), so the
# type ids in the decoder are held against what this server writes, not
# against a table in a test file. The source rows are written with plain
# SQL and every comparison of stored values is made by the server.
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
  package My::Undecoded::Schema::Result::Shape;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_undecoded');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package My::Undecoded::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Shape => 'My::Undecoded::Schema::Result::Shape');
}

my $schema = My::Undecoded::Schema->connect(sub { $dbh });

# An untyped column: it takes every geometry type.
eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_undecoded') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_undecoded (
  id   serial primary key,
  name text,
  geom geometry
)
SQL

END { eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_undecoded') } if $dbh }

my $rs = $schema->resultset('Shape');
my $G  = 'DBIO::PostgreSQL::PostGIS::Geometry';

# Does row $copy hold the geometry of row $src, byte for byte?
my $is_copy = sub {
  my ($src_id, $copy_id, $how) = @_;
  my ($same, $src_ewkt, $copy_ewkt) = $dbh->selectrow_array(<<'SQL', undef, $src_id, $copy_id);
SELECT ST_AsEWKB(s.geom) = ST_AsEWKB(c.geom), ST_AsEWKT(s.geom), ST_AsEWKT(c.geom)
  FROM dbio_postgis_test_undecoded s, dbio_postgis_test_undecoded c
 WHERE s.id = ? AND c.id = ?
SQL
  ok $same, "$how: the row holds the same EWKB as the one it was read from"
    or diag 'read from: ' . ($src_ewkt // 'NULL')
          . "\nwritten:   " . ($copy_ewkt // 'NULL');
};

# One of each type the decoder does not decode, and a collection of a
# decoded and an undecoded member -- not decoded either, as a whole.
my @shapes = (
  'CIRCULARSTRING(0 0,1 1,2 0)',
  'COMPOUNDCURVE(CIRCULARSTRING(0 0,1 1,2 0),(2 0,3 0))',
  'CURVEPOLYGON(CIRCULARSTRING(0 0,4 0,4 4,0 4,0 0))',
  'MULTICURVE((0 0,5 5),CIRCULARSTRING(4 0,4 4,8 4))',
  'MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0,4 0,4 4,0 4,0 0)),((10 10,14 12,11 10,10 10)))',
  'POLYHEDRALSURFACE(((0 0 0,0 0 1,0 1 1,0 1 0,0 0 0)),((0 0 0,0 1 0,1 1 0,1 0 0,0 0 0)))',
  'TIN(((0 0 0,0 0 1,0 1 0,0 0 0)),((0 0 0,0 1 0,1 1 0,0 0 0)))',
  'TRIANGLE((0 0,0 9,9 0,0 0))',
  'GEOMETRYCOLLECTION(POINT(1 2),CIRCULARSTRING(0 0,1 1,2 0))',
);

for my $wkt (@shapes) {
  my ($type) = $wkt =~ /\A(\w+)/;

  subtest "read and write back: $type" => sub {
    my ($src_id) = $dbh->selectrow_array(<<'SQL', undef, $wkt, $wkt);
INSERT INTO dbio_postgis_test_undecoded (name, geom)
VALUES (?, ST_GeomFromText(?, 4326))
RETURNING id
SQL
    my ($server_type, $server_srid, $server_hex)
      = $dbh->selectrow_array(<<'SQL', undef, $src_id);
SELECT GeometryType(geom), ST_SRID(geom), geom::text
  FROM dbio_postgis_test_undecoded WHERE id = ?
SQL
    is $server_type, $type, 'the server stored the type the fixture names';

    my $src  = $rs->find($src_id);
    my $geom = $src->geom;
    isa_ok $geom, $G, 'a row that holds a geometry reads as an object, and it'
      or return;

    is lc($geom->geometry_type // ''), lc $server_type,
      "geometry_type is the server's GeometryType, whatever the case";
    is $geom->srid, $server_srid, "srid is the server's ST_SRID";
    is $geom->ewkb_hex, $server_hex, 'ewkb_hex is the hex the server sent';

    # INSERT with the read object
    my $created = eval { $rs->create({ name => "$type (create)", geom => $geom }) };
    ok $created, 'create with the read geometry' or diag $@;
    $is_copy->($src_id, $created->id, 'create') if $created;

    # UPDATE of a row that held something else
    my $target = $rs->create({
      name => "$type (update)",
      geom => $G->point(0, 0, srid => 4326),
    });
    $target->geom($geom);
    ok eval { $target->update; 1 }, 'update with the read geometry'
      or diag $@;
    $is_copy->($src_id, $target->id, 'update');

    # Written back to where it came from, it is the value already there.
    $src->geom($geom);
    ok !$src->is_column_changed('geom'),
      'setting the read geometry on its own row leaves the column clean';
  };
}

# The row this is told apart from.
subtest 'a row that holds NULL still reads as undef' => sub {
  my ($null_id) = $dbh->selectrow_array(<<'SQL');
INSERT INTO dbio_postgis_test_undecoded (name, geom)
VALUES ('no geometry', NULL)
RETURNING id
SQL
  my $row = $rs->find($null_id);
  ok $row, 'the row is found' or return;
  my $geom = $row->geom;
  is $geom, undef, 'geom is undef';
};

done_testing;
