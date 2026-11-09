use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Geometry;
my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';

# from_wkt → to_wkt round-trip
my $g = $G->from_wkt('POLYGON((0 0,10 0,10 10,0 10,0 0))', srid => 4326);
is $g->to_wkt, 'POLYGON((0 0,10 0,10 10,0 10,0 0))', 'to_wkt round-trip';
is $g->srid,   4326,                                   'srid preserved';

# POINT Z
my $g2 = $G->from_wkt('POINT Z(1 2 3)');
is $g2->geometry_type, 'POINT', 'POINT Z type';
is $g2->to_wkt,        'POINT Z(1 2 3)', 'POINT Z round-trip';

# from_ewkb_hex now actually decodes
use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
my $hex = unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 5.0, 6.0));
my $g3  = $G->from_ewkb_hex($hex);
is $g3->geometry_type,  'POINT', 'from_ewkb_hex type';
is $g3->srid,           4326,    'from_ewkb_hex srid';
is $g3->coordinates->[0], 5.0,  'from_ewkb_hex x';

# A geometry decoded from EWKB hex has no stored WKT: wkt/ewkt build it
# from the decoded coordinates (karr k14). The dimension marker has to
# come from the Z/M flags of the EWKB, never from the shape of the
# coordinate list -- coordinates->[2] is the third ORDINATE of a point but
# the third POINT of a line and the third RING of a polygon. And what is
# built has to read back, through this dist's own parser, as the same
# coordinates with the same flags.
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
my $P = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser';

my ($Z, $M, $SRID) = (0x80000000, 0x40000000, 0x20000000);
my $head   = sub { pack 'C V', 1, $_[0] };
my $points = sub { join '', map { pack 'd<*', @$_ } @_ };
my $ring   = sub { pack('V', scalar @_) . $points->(@_) };
my $hex_of = sub { unpack 'H*', join '', @_ };

my @from_ewkb = (
  {
    name   => '2D line, three points',
    hex    => $hex_of->($head->(2), $ring->([0,0],[1,1],[2,2])),
    wkt    => 'LINESTRING(0 0,1 1,2 2)',
    coords => [[0,0],[1,1],[2,2]],
  },
  {
    name   => '2D multipoint, three points',
    hex    => $hex_of->($head->(4), pack('V', 3),
      map { $head->(1) . $points->($_) } [1,2],[3,4],[5,6]),
    wkt    => 'MULTIPOINT(1 2,3 4,5 6)',
    coords => [[1,2],[3,4],[5,6]],
  },
  {
    name   => '2D polygon, three rings',
    hex    => $hex_of->($head->(3), pack('V', 3),
      $ring->([0,0],[9,0],[9,9],[0,0]),
      $ring->([1,1],[2,1],[2,2],[1,1]),
      $ring->([5,5],[6,5],[6,6],[5,5])),
    wkt    => 'POLYGON((0 0,9 0,9 9,0 0),(1 1,2 1,2 2,1 1),(5 5,6 5,6 6,5 5))',
    coords => [
      [[0,0],[9,0],[9,9],[0,0]],
      [[1,1],[2,1],[2,2],[1,1]],
      [[5,5],[6,5],[6,6],[5,5]],
    ],
  },
  {
    name   => 'point M',
    hex    => $hex_of->($head->(1 | $M), $points->([1,2,9])),
    wkt    => 'POINT M(1 2 9)',
    coords => [1,2,9],
    has_m  => 1,
  },
  {
    name   => 'point Z',
    hex    => $hex_of->($head->(1 | $Z), $points->([1,2,3])),
    wkt    => 'POINT Z(1 2 3)',
    coords => [1,2,3],
    has_z  => 1,
  },
  {
    name   => 'point ZM',
    hex    => $hex_of->($head->(1 | $Z | $M), $points->([1,2,3,4])),
    wkt    => 'POINT ZM(1 2 3 4)',
    coords => [1,2,3,4],
    has_z  => 1,
    has_m  => 1,
  },
  {
    name   => '3D line, two points',
    hex    => $hex_of->($head->(2 | $Z), $ring->([0,0,5],[1,1,6])),
    wkt    => 'LINESTRING Z(0 0 5,1 1 6)',
    coords => [[0,0,5],[1,1,6]],
    has_z  => 1,
  },
  {
    name   => '3D line, three points',
    hex    => $hex_of->($head->(2 | $Z), $ring->([0,0,5],[1,1,6],[2,2,7])),
    wkt    => 'LINESTRING Z(0 0 5,1 1 6,2 2 7)',
    coords => [[0,0,5],[1,1,6],[2,2,7]],
    has_z  => 1,
  },
  {
    name   => 'M line, three points',
    hex    => $hex_of->($head->(2 | $M), $ring->([0,0,5],[1,1,6],[2,2,7])),
    wkt    => 'LINESTRING M(0 0 5,1 1 6,2 2 7)',
    coords => [[0,0,5],[1,1,6],[2,2,7]],
    has_m  => 1,
  },
);

for my $case (@from_ewkb) {
  subtest "from EWKB hex to WKT and back: $case->{name}" => sub {
    my $g = $G->from_ewkb_hex($case->{hex});
    ok $g, 'decodes' or return;
    is_deeply $g->coordinates, $case->{coords}, 'decoded coordinates';
    is $g->wkt,    $case->{wkt}, 'wkt';
    is $g->to_wkt, $case->{wkt}, 'to_wkt';
    is $g->ewkt,   $case->{wkt}, 'ewkt without an SRID is the bare WKT';

    my $back = $P->parse($g->wkt);
    ok $back, 'the built WKT parses' or return;
    is_deeply $back->{coords}, $case->{coords},
      '... to the coordinates the EWKB carried';
    is $back->{has_z}, $case->{has_z} ? 1 : 0, '... with the same Z flag';
    is $back->{has_m}, $case->{has_m} ? 1 : 0, '... with the same M flag';
  };
}

subtest 'ewkt of a decoded line carries the SRID of the EWKB' => sub {
  my $g = $G->from_ewkb_hex($hex_of->(
    $head->(2 | $SRID), pack('V', 4326), $ring->([0,0],[1,1],[2,2]),
  ));
  ok $g, 'decodes' or return;
  is $g->ewkt, 'SRID=4326;LINESTRING(0 0,1 1,2 2)';
};

# An object built from bare coordinates has no flags to go by. The
# dimension is then read off one point: three ordinates are Z, four ZM --
# never off the number of points or rings. has_z / has_m given to new
# decide over that (three ordinates can only be told to be M).
subtest 'to_wkt of an object built from coordinates' => sub {
  my $wkt = sub { $G->new(@_)->to_wkt };
  is $wkt->(geometry_type => 'POINT', coordinates => [1,2]),
    'POINT(1 2)', '2D point';
  is $wkt->(geometry_type => 'POINT', coordinates => [1,2,3]),
    'POINT Z(1 2 3)', '3D point';
  is $wkt->(geometry_type => 'POINT', coordinates => [1,2,3,4]),
    'POINT ZM(1 2 3 4)', '4D point';
  is $wkt->(geometry_type => 'POINT', coordinates => [1,2,9], has_m => 1),
    'POINT M(1 2 9)', 'has_m given to new decides for three ordinates';
  is $wkt->(geometry_type => 'LINESTRING', coordinates => [[0,0],[1,1],[2,2]]),
    'LINESTRING(0 0,1 1,2 2)', '2D line of three points';
  is $wkt->(geometry_type => 'LINESTRING', coordinates => [[0,0,5],[1,1,6]]),
    'LINESTRING Z(0 0 5,1 1 6)', '3D line of two points';
  is $wkt->(
    geometry_type => 'POLYGON',
    coordinates   => [
      [[0,0],[9,0],[9,9],[0,0]],
      [[1,1],[2,1],[2,2],[1,1]],
      [[5,5],[6,5],[6,6],[5,5]],
    ],
  ), 'POLYGON((0 0,9 0,9 9,0 0),(1 1,2 1,2 2,1 1),(5 5,6 5,6 6,5 5))',
    '2D polygon of three rings';
};

# from_geojson writes MULTIPOINT without the per-point parentheses. Both
# forms are valid WKT; the parser has to read the one this dist writes.
subtest 'from_geojson MultiPoint survives the way through its WKT' => sub {
  my $gj = { type => 'MultiPoint', coordinates => [[1,2],[3,4],[5,6]] };
  my $g  = $G->from_geojson($gj);
  is_deeply $g->coordinates, $gj->{coordinates}, 'coordinates';
  is_deeply $g->to_geojson,  $gj,                'to_geojson';

  my $again = $G->from_wkt($g->wkt);
  is_deeply $again->coordinates, $gj->{coordinates},
    'coordinates of the object rebuilt from its WKT';
  is_deeply $again->to_geojson, $gj,
    'to_geojson of the object rebuilt from its WKT';
};

# Empty geometries read from EWKB (karr k19). They carried no flag, and
# is_empty looked for "EMPTY" in a WKT that was never built, so every empty
# geometry read from the database said it was not empty and built
# "LINESTRING()" or "POINT(NaN NaN)". PostGIS writes POINT EMPTY as a point
# of NaN ordinates and every other empty geometry as a count of 0.
my $NaN = 'NaN' + 0;
my $EMPTY_POINT = $hex_of->($head->(1 | $SRID), pack('V', 4326), pack('d< d<', $NaN, $NaN));
for my $case (
  [ 'POINT EMPTY', $EMPTY_POINT, 'point', 'POINT EMPTY', 'Point' ],
  [ 'POINT Z EMPTY',
    $hex_of->($head->(1 | $SRID | $Z), pack('V', 4326), pack('d< d< d<', $NaN, $NaN, $NaN)),
    'point', 'POINT Z EMPTY', 'Point' ],
  [ 'POINT M EMPTY',
    $hex_of->($head->(1 | $SRID | $M), pack('V', 4326), pack('d< d< d<', $NaN, $NaN, $NaN)),
    'point', 'POINT M EMPTY', 'Point' ],
  [ 'LINESTRING EMPTY', $hex_of->($head->(2 | $SRID), pack('V', 4326), pack('V', 0)),
    'linestring', 'LINESTRING EMPTY', 'LineString' ],
  [ 'LINESTRING ZM EMPTY', $hex_of->($head->(2 | $SRID | $Z | $M), pack('V', 4326), pack('V', 0)),
    'linestring', 'LINESTRING ZM EMPTY', 'LineString' ],
  [ 'POLYGON EMPTY', $hex_of->($head->(3 | $SRID), pack('V', 4326), pack('V', 0)),
    'polygon', 'POLYGON EMPTY', 'Polygon' ],
  [ 'MULTIPOINT EMPTY', $hex_of->($head->(4 | $SRID), pack('V', 4326), pack('V', 0)),
    'multipoint', 'MULTIPOINT EMPTY', 'MultiPoint' ],
  [ 'MULTILINESTRING EMPTY', $hex_of->($head->(5 | $SRID), pack('V', 4326), pack('V', 0)),
    'multilinestring', 'MULTILINESTRING EMPTY', 'MultiLineString' ],
  [ 'MULTIPOLYGON EMPTY', $hex_of->($head->(6 | $SRID), pack('V', 4326), pack('V', 0)),
    'multipolygon', 'MULTIPOLYGON EMPTY', 'MultiPolygon' ],
) {
  my ($name, $hex, $type, $wkt, $gj_type) = @$case;
  subtest "empty from EWKB: $name" => sub {
    my $g = $G->from_ewkb_hex($hex);
    ok $g, 'decodes' or return;
    is $g->geometry_type, uc $type, 'type';
    ok $g->is_empty, 'is_empty';
    is $g->wkt,    $wkt, 'wkt';
    is $g->to_wkt, $wkt, 'to_wkt';
    is $g->ewkt,   "SRID=4326;$wkt", 'ewkt';
    is_deeply $g->coordinates, [], 'coordinates are an empty list, not [NaN, NaN]';
    is $g->bbox, undef, 'no bbox';
    is $g->x, undef, 'no x';
    is_deeply $g->to_geojson, { type => $gj_type, coordinates => [] },
      'to_geojson: the type with empty coordinates, as ST_AsGeoJSON';
    is $g->ewkb_hex, $hex, 'the hex is the value, as given';

    my $back = $P->parse($g->wkt);
    ok $back && $back->{is_empty}, 'the built WKT parses as empty';
  };
}

subtest 'a geometry that is not empty is not' => sub {
  for my $hex (
    $hex_of->($head->(1), pack('d< d<', 1, 2)),
    $hex_of->($head->(1), pack('d< d<', $NaN, 2)),
    $hex_of->($head->(2), $ring->([0,0],[1,1])),
  ) {
    my $g = $G->from_ewkb_hex($hex);
    ok !$g->is_empty, 'is_empty is false: ' . $g->wkt;
  }
  my $curve = $G->from_ewkb_hex(
    '0108000020E61000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000'
  );
  ok !$curve->is_empty, 'a value that is not decoded: false, nothing is known';
};

# The same for a geometry made from WKT (karr k19).
subtest 'empty from WKT' => sub {
  for my $case (
    [ 'POINT EMPTY',            'Point' ],
    [ 'LINESTRING EMPTY',       'LineString' ],
    [ 'POLYGON EMPTY',          'Polygon' ],
    [ 'MULTIPOINT EMPTY',       'MultiPoint' ],
    [ 'POINT Z EMPTY',          'Point' ],
  ) {
    my ($wkt, $gj_type) = @$case;
    my $g = $G->from_wkt($wkt);
    ok $g->is_empty, "$wkt: is_empty";
    is $g->wkt, $wkt, "$wkt: wkt";
    is_deeply $g->to_geojson, { type => $gj_type, coordinates => [] },
      "$wkt: to_geojson, the same as for the EWKB-read one";
  }
  is_deeply $G->from_wkt('GEOMETRYCOLLECTION EMPTY')->to_geojson,
    { type => 'GeometryCollection', geometries => [] }, 'GEOMETRYCOLLECTION EMPTY: no geometries';
  ok $G->from_wkt('GEOMETRYCOLLECTION EMPTY')->is_empty, 'GEOMETRYCOLLECTION EMPTY is empty';

  # Nothing but empty parts is empty; one real part is not (ST_IsEmpty).
  ok  $G->from_wkt('MULTIPOINT(EMPTY)')->is_empty, 'MULTIPOINT(EMPTY): empty';
  ok  $G->from_wkt('GEOMETRYCOLLECTION(POINT EMPTY,POLYGON EMPTY)')->is_empty,
    'a collection of empty members: empty';
  ok !$G->from_wkt('MULTIPOINT(EMPTY,(1 2))')->is_empty, 'MULTIPOINT(EMPTY,(1 2)): not empty';
  ok !$G->from_wkt('POINT(1 2)')->is_empty, 'POINT(1 2): not empty';
};

# A GEOMETRYCOLLECTION read from EWKB (karr k24): the members come with
# their types, so the WKT is the collection, with its dimension.
subtest 'a collection read from EWKB' => sub {
  my $hex = $hex_of->(
    $head->(7 | $SRID), pack('V', 4326), pack('V', 2),
    $head->(1), pack('d< d<', 1, 2),
    $head->(2), $ring->([0,0],[1,1]),
  );
  my $g = $G->from_ewkb_hex($hex);
  is $g->geometry_type, 'GEOMETRYCOLLECTION', 'type';
  is $g->wkt, 'GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 'wkt';
  is $g->ewkt, 'SRID=4326;GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 'ewkt';
  ok !$g->is_empty, 'not empty';
  is_deeply $g->coordinates, [
    { type => 'point',      coords => [1,2],         is_empty => 0 },
    { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 },
  ], 'coordinates: the members, each with its type';
  is_deeply $g->bbox, [0,0,1,2], 'bbox over the members';
  is_deeply $g->to_geojson, {
    type       => 'GeometryCollection',
    geometries => [
      { type => 'Point',      coordinates => [1,2] },
      { type => 'LineString', coordinates => [[0,0],[1,1]] },
    ],
  }, 'to_geojson: a GeometryCollection of the members, as ST_AsGeoJSON';
  is $g->ewkb_hex, $hex, 'the hex is kept';


  my $z = $G->from_ewkb_hex($hex_of->(
    $head->(7 | $SRID | $Z), pack('V', 4326), pack('V', 2),
    $head->(1 | $Z), pack('d< d< d<', 1, 2, 3),
    $head->(2 | $Z), $ring->([0,0,1],[1,1,2]),
  ));
  is $z->wkt, 'GEOMETRYCOLLECTION Z(POINT Z(1 2 3),LINESTRING Z(0 0 1,1 1 2))', 'a Z collection';

  my $m = $G->from_ewkb_hex($hex_of->(
    $head->(7 | $SRID | $M), pack('V', 4326), pack('V', 1),
    $head->(1 | $M), pack('d< d< d<', 1, 2, 3),
  ));
  is $m->wkt, 'GEOMETRYCOLLECTION M(POINT M(1 2 3))', 'an M collection';

  my $mixed = $G->from_ewkb_hex($hex_of->(
    $head->(7 | $SRID), pack('V', 4326), pack('V', 2),
    $head->(1), pack('d< d<', $NaN, $NaN),
    $head->(3), pack('V', 0),
  ));
  is $mixed->wkt, 'GEOMETRYCOLLECTION(POINT EMPTY,POLYGON EMPTY)', 'empty members';
  ok $mixed->is_empty, 'a collection of empty members is empty';
  is_deeply $mixed->to_geojson,
    { type => 'GeometryCollection', geometries => [
      { type => 'Point', coordinates => [] }, { type => 'Polygon', coordinates => [] },
    ] }, 'to_geojson keeps the empty members';

  my $nested = $G->from_ewkb_hex($hex_of->(
    $head->(7 | $SRID), pack('V', 4326), pack('V', 2),
    $head->(7), pack('V', 1), $head->(1), pack('d< d<', 1, 2),
    $head->(1), pack('d< d<', 3, 4),
  ));
  is $nested->wkt, 'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))', 'nested';
  is_deeply $nested->bbox, [1,2,3,4], 'bbox of a nested collection';

  my $emptyc = $G->from_ewkb_hex($hex_of->($head->(7 | $SRID), pack('V', 4326), pack('V', 0)));
  is $emptyc->wkt, 'GEOMETRYCOLLECTION EMPTY', 'GEOMETRYCOLLECTION EMPTY';
  ok $emptyc->is_empty, 'is empty';
  is_deeply $emptyc->to_geojson, { type => 'GeometryCollection', geometries => [] },
    'to_geojson: no geometries';

  # One that is not decoded has no members to build from.
  my $curved = $G->from_ewkb_hex(
    '0107000020E6100000020000000101000000000000000000F03F000000000000004001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000'
  );
  is $curved->wkt, undef, 'a collection with an undecoded member: no wkt';
  is $curved->to_geojson, undef, '... and no to_geojson';
  is $curved->bbox, undef, '... and no bbox';
};

# The EWKT ST_AsEWKT prints: M glued to the type, Z and ZM without a
# marker (karr k21). The type is the type, not POINTM; the coordinates are
# there; the text is kept as it came.
subtest 'EWKT as ST_AsEWKT prints it' => sub {
  my $m = $G->from_ewkt('SRID=4326;POINTM(1 2 9)');
  is $m->geometry_type, 'POINT', 'POINTM: the type is point';
  is $m->srid, 4326, '... srid';
  is_deeply $m->coordinates, [1, 2, 9], '... coordinates';
  is $m->wkt,  'POINTM(1 2 9)', '... wkt is the text given';
  is $m->ewkt, 'SRID=4326;POINTM(1 2 9)', '... ewkt round-trips';
  is_deeply $m->bbox, [1, 2, 1, 2], '... bbox';
  is_deeply $m->to_geojson, { type => 'Point', coordinates => [1, 2, 9] }, '... to_geojson';
  ok !$m->is_empty, '... not empty';

  # Built from what the parser read, the object writes the marker as the
  # builder does, and the parser reads that again.
  my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($m->wkt);
  ok $parsed->{has_m} && !$parsed->{has_z}, '... the parser says M, not Z';
  my $built = $G->new(
    srid => 4326, geometry_type => $parsed->{type}, coordinates => $parsed->{coords},
    has_z => $parsed->{has_z}, has_m => $parsed->{has_m},
  );
  is $built->wkt, 'POINT M(1 2 9)', '... built from the parsed parts: the builder writes M';

  for my $c (
    [ 'MULTIPOINTM(1 2 9,3 4 8)',          'multipoint',      [[1,2,9],[3,4,8]] ],
    [ 'LINESTRINGM(0 0 1,1 1 2)',          'linestring',      [[0,0,1],[1,1,2]] ],
    [ 'POLYGONM((0 0 1,1 0 1,1 1 1,0 0 1))', 'polygon',       [[[0,0,1],[1,0,1],[1,1,1],[0,0,1]]] ],
    [ 'MULTILINESTRINGM((0 0 1,1 1 2))',   'multilinestring', [[[0,0,1],[1,1,2]]] ],
    [ 'MULTIPOLYGONM(((0 0 1,1 0 1,1 1 1,0 0 1)))', 'multipolygon', [[[[0,0,1],[1,0,1],[1,1,1],[0,0,1]]]] ],
    [ 'POINT(1 2 3 4)',                    'point',           [1,2,3,4] ],
    [ 'LINESTRING(0 0 5,1 1 6)',           'linestring',      [[0,0,5],[1,1,6]] ],
  ) {
    my ($ewkt, $type, $coords) = @$c;
    my $g = $G->from_ewkt("SRID=4326;$ewkt");
    is $g->geometry_type, uc $type, "$ewkt: type";
    is_deeply $g->coordinates, $coords, "$ewkt: coordinates";
    is $g->ewkt, "SRID=4326;$ewkt", "$ewkt: ewkt as given";
  }

  ok $G->from_ewkt('SRID=4326;POINTM EMPTY')->is_empty, 'POINTM EMPTY is empty';
  is_deeply $G->from_ewkt('SRID=4326;POINTM EMPTY')->coordinates, [], '... and has no coordinates';
};

subtest 'a collection and empty parts from WKT' => sub {
  my $g = $G->from_ewkt('SRID=4326;GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,5 1))');
  is $g->geometry_type, 'GEOMETRYCOLLECTION', 'type';
  is_deeply $g->coordinates, [
    { type => 'point',      coords => [1, 2],         is_empty => 0 },
    { type => 'linestring', coords => [[0,0],[5,1]],  is_empty => 0 },
  ], 'the members, as the EWKB decoder has them';
  is_deeply $g->bbox, [0, 0, 5, 2], 'bbox';
  is_deeply $g->to_geojson, {
    type => 'GeometryCollection',
    geometries => [
      { type => 'Point',      coordinates => [1, 2] },
      { type => 'LineString', coordinates => [[0,0],[5,1]] },
    ],
  }, 'to_geojson';

  my $m = $G->from_ewkt('SRID=4326;GEOMETRYCOLLECTIONM(POINTM(1 2 3))');
  is_deeply $m->coordinates, [ { type => 'point', coords => [1,2,3], is_empty => 0 } ],
    'an M collection with an M member';

  # The same collection from WKT and from the EWKB of the same geometry.
  my $parsed = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse('GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))');
  my $ewkb = $G->from_ewkb_hex(unpack 'H*', pack('C V V' . ('C V d< d<') . ('C V V (d< d<)2'),
    1, 7, 2,  1, 1, 1, 2,  1, 2, 2, 0, 0, 1, 1));
  is_deeply $ewkb->coordinates, $parsed->{coords}, 'the structure the EWKB decoder gives';

  my $mp = $G->from_wkt('MULTIPOINT(EMPTY,(1 2))');
  is_deeply $mp->coordinates, [[], [1, 2]], 'MULTIPOINT(EMPTY,(1 2)): the empty part keeps its place';
  ok !$mp->is_empty, '... and the whole is not empty';
  is_deeply $mp->to_geojson, { type => 'MultiPoint', coordinates => [[], [1, 2]] }, '... to_geojson';
  is_deeply $mp->bbox, [1, 2, 1, 2], '... bbox';
};

done_testing;
