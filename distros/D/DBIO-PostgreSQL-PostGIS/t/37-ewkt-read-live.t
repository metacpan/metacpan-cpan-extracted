use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;

# Live read of the text PostGIS prints (karr k21).
#
# A column selected as ST_AsEWKT(geom) comes back as EWKT, and for a
# measured geometry that is "POINTM(1 2 9)" -- the M glued to the type --
# where ST_AsText prints "POINT M (1 2 9)"; Z and ZM carry no marker at
# all, and a collection or an empty part of a MULTI* is text too. The
# parser used to read none of POINTM, the collections and the empty
# parts, and the object had no coordinates.
#
# Rows are written with plain SQL (ST_GeomFromEWKT), so they owe nothing to
# the code under test. Every claim is held against the server's own
# reading of the same row:
#
#  - what the object read from ST_AsEWKT(geom) says (type, coordinates,
#    emptiness) is what the EWKB decoder says of ST_AsEWKB(geom), and the
#    parser reads ST_AsText the same way;
#  - has_z / has_m of the parsed text are those of the EWKB header (not for
#    an empty Z or ZM geometry, where ST_AsEWKT prints no marker at all and
#    the dimension is lost on the server's side of the line);
#  - what the builder makes of the parsed text is read by the server as the
#    very geometry of the row, bit for bit (ST_AsEWKB).
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
  package My::EwktRead::Schema::Result::Shape;
  use base 'DBIO::Core';
  __PACKAGE__->load_components(qw( PostgreSQL::PostGIS ));
  __PACKAGE__->table('dbio_postgis_test_ewkt_read');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
    geom => { data_type => 'geometry', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package My::EwktRead::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
  __PACKAGE__->register_class(Shape => 'My::EwktRead::Schema::Result::Shape');
}

my $schema = My::EwktRead::Schema->connect(sub { $dbh });

eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_ewkt_read') };
$dbh->do(<<'SQL');
CREATE TABLE dbio_postgis_test_ewkt_read (
  id   serial primary key,
  name text,
  geom geometry
)
SQL

END { eval { $dbh->do('DROP TABLE IF EXISTS dbio_postgis_test_ewkt_read') } if $dbh }

my $rs = $schema->resultset('Shape');
my $G  = 'DBIO::PostgreSQL::PostGIS::Geometry';

# [ the EWKT written, lossy ]
#  lossy: an empty Z or ZM geometry. ST_AsEWKT prints it without the
#         marker ("POINT EMPTY"), so the dimension is not in that text.
my @cases = (
  # M: glued to the type
  [ 'SRID=4326;POINTM(1 2 9)' ],
  [ 'SRID=4326;MULTIPOINTM(1 2 9,3 4 8)' ],
  [ 'SRID=4326;LINESTRINGM(0 0 1,1 1 2)' ],
  [ 'SRID=4326;POLYGONM((0 0 1,1 0 1,1 1 1,0 0 1))' ],
  [ 'SRID=4326;MULTILINESTRINGM((0 0 1,1 1 2),(2 2 3,3 3 4))' ],
  [ 'SRID=4326;MULTIPOLYGONM(((0 0 1,1 0 1,1 1 1,0 0 1)))' ],
  # Z and ZM: no marker
  [ 'SRID=4326;POINT(1 2 3)' ],
  [ 'SRID=4326;POINT(1 2 3 4)' ],
  [ 'SRID=4326;MULTIPOINT(1 2 3,4 5 6)' ],
  [ 'SRID=4326;MULTIPOINT(1 2 3 4,4 5 6 7)' ],
  [ 'SRID=4326;LINESTRING(0 0 1,1 1 2)' ],
  [ 'SRID=4326;LINESTRING(0 0 1 2,1 1 2 3)' ],
  [ 'SRID=4326;POLYGON((0 0 1,1 0 1,1 1 1,0 0 1))' ],
  [ 'SRID=4326;POLYGON((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2))' ],
  [ 'SRID=4326;MULTILINESTRING((0 0 1 2,1 1 2 3))' ],
  [ 'SRID=4326;MULTIPOLYGON(((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2)))' ],
  # 2D, as before
  [ 'SRID=4326;POINT(1 2)' ],
  [ 'SRID=4326;POLYGON((0 0,1 0,1 1,0 0),(0 0,1 0,1 1,0 0))' ],
  # empty, with the marker where the server prints one
  [ 'SRID=4326;POINT EMPTY' ],
  [ 'SRID=4326;POINTM EMPTY' ],
  [ 'SRID=4326;POINT Z EMPTY', 1 ],
  [ 'SRID=4326;POINT ZM EMPTY', 1 ],
  [ 'SRID=4326;LINESTRINGM EMPTY' ],
  [ 'SRID=4326;POLYGONM EMPTY' ],
  [ 'SRID=4326;MULTIPOINTM EMPTY' ],
  [ 'SRID=4326;MULTIPOLYGON ZM EMPTY', 1 ],
  [ 'SRID=4326;GEOMETRYCOLLECTION EMPTY' ],
  [ 'SRID=4326;GEOMETRYCOLLECTIONM EMPTY' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION ZM EMPTY', 1 ],
  # empty parts keep their place
  [ 'SRID=4326;MULTIPOINT(EMPTY,(1 2))' ],
  [ 'SRID=4326;MULTIPOINT((1 2),EMPTY,(3 4))' ],
  [ 'SRID=4326;MULTIPOINT(EMPTY)' ],
  [ 'SRID=4326;MULTIPOINTM(EMPTY,(1 2 3))' ],
  [ 'SRID=4326;MULTILINESTRING(EMPTY,(0 0,1 1))' ],
  [ 'SRID=4326;MULTILINESTRING((0 0,1 1),EMPTY)' ],
  [ 'SRID=4326;MULTILINESTRING(EMPTY)' ],
  [ 'SRID=4326;MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))' ],
  [ 'SRID=4326;MULTIPOLYGON(((0 0,1 0,1 1,0 0)),EMPTY)' ],
  [ 'SRID=4326;MULTIPOLYGON(EMPTY)' ],
  # collections
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT(1 2 3),LINESTRING(0 0 1,1 1 2))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT(1 2 3 4))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTIONM(POINTM(1 2 3),LINESTRINGM(0 0 1,1 1 2))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT EMPTY,LINESTRING(0 0,1 1))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT EMPTY,POLYGON EMPTY)' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(POINT Z EMPTY)', 1 ],
  [ 'SRID=4326;GEOMETRYCOLLECTIONM(POINTM EMPTY)' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(MULTIPOINT(EMPTY,1 2),POINT EMPTY)' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(MULTIPOINT((1 2),(3 4)),MULTILINESTRING((0 0,1 1),(2 2,3 3)),MULTIPOLYGON(((0 0,1 0,1 1,0 0))))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))' ],
  [ 'SRID=4326;GEOMETRYCOLLECTIONM(GEOMETRYCOLLECTIONM(POINTM(1 2 3)),POINTM(3 4 5))' ],
);

# What the object must be, as the EWKB decoder reads the very row.
sub decoded {
  my ($id) = @_;
  my ($hex) = $dbh->selectrow_array(
    'SELECT ST_AsEWKB(geom)::text FROM dbio_postgis_test_ewkt_read WHERE id = ?', undef, $id);
  $hex =~ s/\A\\x//;
  return DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder->decode_hex($hex);
}

for my $case (@cases) {
  my ($ewkt, $lossy) = @$case;

  subtest "read $ewkt" => sub {
    my ($id) = $dbh->selectrow_array(
      'INSERT INTO dbio_postgis_test_ewkt_read (name, geom) '
      . 'VALUES (?, ST_GeomFromEWKT(?)) RETURNING id', undef, $ewkt, $ewkt);

    my $want = decoded($id);
    my ($as_ewkt, $as_text, $is_empty) = $dbh->selectrow_array(
      'SELECT ST_AsEWKT(geom), ST_AsText(geom), ST_IsEmpty(geom) '
      . 'FROM dbio_postgis_test_ewkt_read WHERE id = ?', undef, $id);

    # The column, selected as the text the server prints.
    my $row = $rs->search(
      { 'me.id' => $id },
      { select => [ 'me.id', \'ST_AsEWKT(me.geom)' ], as => [ 'id', 'geom' ] },
    )->next;
    my $g = $row->geom;
    isa_ok $g, $G, "ST_AsEWKT(geom) inflates ($as_ewkt)" or return;

    is $g->srid, 4326, 'srid';
    is lc $g->geometry_type, $want->{type}, 'geometry_type is the type, not POINTM';
    is_deeply $g->coordinates, $want->{coords}, 'coordinates are what the EWKB says'
      or diag "text: $as_ewkt";
    is $g->is_empty ? 1 : 0, $is_empty ? 1 : 0, 'is_empty is what ST_IsEmpty says';
    is $g->wkt, $as_ewkt =~ s/\ASRID=\d+;//r, 'the text is kept as it came';

    for my $form ([ 'ST_AsEWKT', $as_ewkt =~ s/\ASRID=\d+;//r ], [ 'ST_AsText', $as_text ]) {
      my ($how, $text) = @$form;
      my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($text);
      ok $parsed, "$how ($text) is read" or next;
      is $parsed->{type}, $want->{type}, "$how: type";
      is_deeply $parsed->{coords}, $want->{coords}, "$how: coords";
      is $parsed->{is_empty}, $want->{is_empty}, "$how: is_empty";

      my $dims_known = $how eq 'ST_AsText' || !$lossy;
      if ($dims_known) {
        is $parsed->{has_z}, $want->{has_z}, "$how: has_z is that of the EWKB";
        is $parsed->{has_m}, $want->{has_m}, "$how: has_m is that of the EWKB";

        # Parser -> builder -> server: the very geometry.
        my $built = DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder->build($parsed);
        my ($same) = eval {
          $dbh->selectrow_array(
            'SELECT ST_AsEWKB(ST_GeomFromText(?, 4326)) = ST_AsEWKB(geom) '
            . 'FROM dbio_postgis_test_ewkt_read WHERE id = ?', undef, $built, $id);
        };
        diag "built: $built: $@" if $@;
        ok $same, "$how: the built text ($built) is the same geometry, bit for bit";
      }
    }

    # Written to another row the object stores the same geometry.
    my $copy = eval { $rs->create({ name => "$ewkt (copy)", geom => $g }) };
    ok $copy, 'create with the geometry read from ST_AsEWKT' or diag $@ or return;
    my ($same) = $dbh->selectrow_array(
      'SELECT ST_AsEWKB(s.geom) = ST_AsEWKB(c.geom) '
      . 'FROM dbio_postgis_test_ewkt_read s, dbio_postgis_test_ewkt_read c '
      . 'WHERE s.id = ? AND c.id = ?', undef, $id, $copy->id);
    # An empty Z or ZM geometry has no dimension in its EWKT; the copy is
    # 2D there, and that is the text's doing, not a claim made here.
    ok $same, 'the copy holds the same EWKB' unless $lossy;
  };
}

done_testing;
