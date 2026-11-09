use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
my $p = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser';

# POINT
{
  my $r = $p->parse('POINT(13.4 52.5)');
  is $r->{type},              'point',  'POINT type';
  is $r->{coords}[0],         13.4,     'POINT x';
  is $r->{coords}[1],         52.5,     'POINT y';
  ok !$r->{has_z},                      'POINT no Z';
}

# POINT Z
{
  my $r = $p->parse('POINT Z(13.4 52.5 10)');
  is $r->{type},   'point',  'POINT Z type';
  is $r->{coords}[2], 10,   'POINT Z z-coord';
  ok $r->{has_z},           'has_z true';
}

# LINESTRING
{
  my $r = $p->parse('LINESTRING(0 0, 1 1, 2 2)');
  is $r->{type},            'linestring', 'LINESTRING type';
  is scalar @{$r->{coords}}, 3,           '3 points';
  is $r->{coords}[1][0],    1,            'second x';
}

# POLYGON
{
  my $r = $p->parse('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))');
  is $r->{type},             'polygon', 'POLYGON type';
  is scalar @{$r->{coords}}, 1,         '1 ring';
  is scalar @{$r->{coords}[0]}, 5,      '5 points in ring';
}

# POLYGON with hole
{
  my $r = $p->parse('POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,2 1,2 2,1 2,1 1))');
  is scalar @{$r->{coords}}, 2, 'POLYGON 2 rings (outer + hole)';
}

# EMPTY
{
  my $r = $p->parse('POINT EMPTY');
  ok $r->{is_empty}, 'POINT EMPTY flagged';
}

# MULTIPOINT
{
  my $r = $p->parse('MULTIPOINT((0 0),(1 1))');
  is $r->{type},             'multipoint', 'MULTIPOINT type';
  is scalar @{$r->{coords}}, 2,            '2 points';
}

# MULTIPOINT has two valid forms, with and without parentheses around
# each point. PostGIS reads both, ST_AsText writes the first, ST_AsEWKT
# and this dist's own builder the second (karr k14).
for my $form (
  [ 'MULTIPOINT((1 2),(3 4),(5 6))',      [[1,2],[3,4],[5,6]],   0, 0 ],
  [ 'MULTIPOINT(1 2,3 4,5 6)',            [[1,2],[3,4],[5,6]],   0, 0 ],
  [ 'MULTIPOINT(1 2, 3 4)',               [[1,2],[3,4]],         0, 0 ],
  [ 'MULTIPOINT( (1 2) , (3 4) )',        [[1,2],[3,4]],         0, 0 ],
  [ 'MULTIPOINT(1 2)',                    [[1,2]],               0, 0 ],
  [ 'MULTIPOINT Z(1 2 3,4 5 6)',          [[1,2,3],[4,5,6]],     1, 0 ],
  [ 'MULTIPOINT Z ((1 2 3),(4 5 6))',     [[1,2,3],[4,5,6]],     1, 0 ],
  [ 'MULTIPOINT M(1 2 9,3 4 8)',          [[1,2,9],[3,4,8]],     0, 1 ],
  [ 'MULTIPOINT ZM((1 2 3 4),(5 6 7 8))', [[1,2,3,4],[5,6,7,8]], 1, 1 ],
  # PostGIS reads a mix of the two forms.
  [ 'MULTIPOINT((1 2),3 4)',              [[1,2],[3,4]],         0, 0 ],
  # An EMPTY member (ST_AsText and ST_AsEWKT print it) keeps its place
  # as an empty list, as the EWKB decoder has it (karr k21).
  [ 'MULTIPOINT(EMPTY,(1 2))',            [[],[1,2]],            0, 0 ],
) {
  my ($wkt, $coords, $has_z, $has_m) = @$form;
  my $r = $p->parse($wkt);
  is $r->{type}, 'multipoint', "$wkt type";
  is_deeply $r->{coords}, $coords, "$wkt coords";
  is $r->{has_z}, $has_z, "$wkt has_z";
  is $r->{has_m}, $has_m, "$wkt has_m";
}

# The dimension marker: M and ZM beside the Z above
{
  my $r = $p->parse('POINT M(1 2 9)');
  is $r->{type}, 'point', 'POINT M type';
  is_deeply $r->{coords}, [1, 2, 9], 'POINT M coords';
  is $r->{has_z}, 0, 'POINT M is not Z';
  is $r->{has_m}, 1, 'POINT M is M';
}
{
  my $r = $p->parse('POINT ZM(1 2 3 4)');
  is $r->{type}, 'point', 'POINT ZM type';
  is_deeply $r->{coords}, [1, 2, 3, 4], 'POINT ZM coords';
  is $r->{has_z}, 1, 'POINT ZM is Z';
  is $r->{has_m}, 1, 'POINT ZM is M';
}

# Every form the server prints, measured against PostGIS (karr k21).
#
#  ST_AsEWKT  M glued to the type (POINTM(1 2 9), MULTIPOINTM(...)); Z and
#             ZM carry no marker at all: POINT(1 2 3) is Z, POINT(1 2 3 4)
#             is ZM -- the ordinates say so. An empty Z or ZM prints as
#             plain "POINT EMPTY" (the dimension is lost there).
#  ST_AsText  the marker as a word of its own: POINT M (1 2 9),
#             POINT Z (1 2 3), POINT ZM (1 2 3 4).
#  this dist's builder: POINT M(1 2 9).
# PostGIS reads all of them, and also POINTZ(...), POINTZM(...).
my $RING_M  = [[0,0,1],[1,0,1],[1,1,1],[0,0,1]];
my $RING_ZM = [[0,0,1,2],[1,0,1,2],[1,1,1,2],[0,0,1,2]];
my $TRI     = [[0,0],[1,0],[1,1],[0,0]];
# [ wkt, type, has_z, has_m, is_empty, coords ]
my @forms = (
  # POINT
  [ 'POINTM(1 2 9)',          'point', 0, 1, 0, [1,2,9] ],
  [ 'POINT M (1 2 9)',        'point', 0, 1, 0, [1,2,9] ],
  [ 'POINT M(1 2 9)',         'point', 0, 1, 0, [1,2,9] ],
  [ 'pointm(1 2 9)',          'point', 0, 1, 0, [1,2,9] ],
  [ 'point m (1 2 9)',        'point', 0, 1, 0, [1,2,9] ],
  [ 'POINT  M  ( 1  2  9 )',  'point', 0, 1, 0, [1,2,9] ],
  [ 'POINT(1 2 3)',           'point', 1, 0, 0, [1,2,3] ],
  [ 'POINT Z (1 2 3)',        'point', 1, 0, 0, [1,2,3] ],
  [ 'POINTZ(1 2 3)',          'point', 1, 0, 0, [1,2,3] ],
  [ 'POINT(1 2 3 4)',         'point', 1, 1, 0, [1,2,3,4] ],
  [ 'POINT ZM (1 2 3 4)',     'point', 1, 1, 0, [1,2,3,4] ],
  [ 'POINTZM(1 2 3 4)',       'point', 1, 1, 0, [1,2,3,4] ],
  [ 'POINT(1 2)',             'point', 0, 0, 0, [1,2] ],
  # MULTIPOINT
  [ 'MULTIPOINTM(1 2 9,3 4 8)',        'multipoint', 0, 1, 0, [[1,2,9],[3,4,8]] ],
  [ 'MULTIPOINT M ((1 2 9),(3 4 8))',  'multipoint', 0, 1, 0, [[1,2,9],[3,4,8]] ],
  [ 'MULTIPOINT(1 2 3,4 5 6)',         'multipoint', 1, 0, 0, [[1,2,3],[4,5,6]] ],
  [ 'MULTIPOINT Z ((1 2 3),(4 5 6))',  'multipoint', 1, 0, 0, [[1,2,3],[4,5,6]] ],
  [ 'MULTIPOINT(1 2 3 4,4 5 6 7)',     'multipoint', 1, 1, 0, [[1,2,3,4],[4,5,6,7]] ],
  [ 'MULTIPOINT ZM ((1 2 3 4),(4 5 6 7))', 'multipoint', 1, 1, 0, [[1,2,3,4],[4,5,6,7]] ],
  # LINESTRING
  [ 'LINESTRINGM(0 0 1,1 1 2)',        'linestring', 0, 1, 0, [[0,0,1],[1,1,2]] ],
  [ 'LINESTRING M (0 0 1,1 1 2)',      'linestring', 0, 1, 0, [[0,0,1],[1,1,2]] ],
  [ 'LINESTRING(0 0 1,1 1 2)',         'linestring', 1, 0, 0, [[0,0,1],[1,1,2]] ],
  [ 'LINESTRING Z (0 0 1,1 1 2)',      'linestring', 1, 0, 0, [[0,0,1],[1,1,2]] ],
  [ 'LINESTRING(0 0 1 2,1 1 2 3)',     'linestring', 1, 1, 0, [[0,0,1,2],[1,1,2,3]] ],
  [ 'LINESTRING ZM (0 0 1 2,1 1 2 3)', 'linestring', 1, 1, 0, [[0,0,1,2],[1,1,2,3]] ],
  # POLYGON
  [ 'POLYGONM((0 0 1,1 0 1,1 1 1,0 0 1))',   'polygon', 0, 1, 0, [$RING_M] ],
  [ 'POLYGON M ((0 0 1,1 0 1,1 1 1,0 0 1))', 'polygon', 0, 1, 0, [$RING_M] ],
  [ 'POLYGON((0 0 1,1 0 1,1 1 1,0 0 1))',    'polygon', 1, 0, 0, [$RING_M] ],
  [ 'POLYGON((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2))', 'polygon', 1, 1, 0, [$RING_ZM] ],
  [ 'POLYGON ZM ((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2))', 'polygon', 1, 1, 0, [$RING_ZM] ],
  # MULTILINESTRING
  [ 'MULTILINESTRINGM((0 0 1,1 1 2),(2 2 3,3 3 4))', 'multilinestring', 0, 1, 0,
    [[[0,0,1],[1,1,2]],[[2,2,3],[3,3,4]]] ],
  [ 'MULTILINESTRING M ((0 0 1,1 1 2))',  'multilinestring', 0, 1, 0, [[[0,0,1],[1,1,2]]] ],
  [ 'MULTILINESTRING((0 0 1 2,1 1 2 3))', 'multilinestring', 1, 1, 0, [[[0,0,1,2],[1,1,2,3]]] ],
  [ 'MULTILINESTRING ZM ((0 0 1 2,1 1 2 3))', 'multilinestring', 1, 1, 0, [[[0,0,1,2],[1,1,2,3]]] ],
  # MULTIPOLYGON
  [ 'MULTIPOLYGONM(((0 0 1,1 0 1,1 1 1,0 0 1)))',    'multipolygon', 0, 1, 0, [[$RING_M]] ],
  [ 'MULTIPOLYGON M (((0 0 1,1 0 1,1 1 1,0 0 1)))',  'multipolygon', 0, 1, 0, [[$RING_M]] ],
  [ 'MULTIPOLYGON(((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2)))', 'multipolygon', 1, 1, 0, [[$RING_ZM]] ],
  [ 'MULTIPOLYGON ZM (((0 0 1 2,1 0 1 2,1 1 1 2,0 0 1 2)))', 'multipolygon', 1, 1, 0, [[$RING_ZM]] ],
  # EMPTY, with and without a marker
  [ 'POINT EMPTY',            'point', 0, 0, 1, [] ],
  [ 'POINT M EMPTY',          'point', 0, 1, 1, [] ],
  [ 'POINTM EMPTY',           'point', 0, 1, 1, [] ],
  [ 'POINT Z EMPTY',          'point', 1, 0, 1, [] ],
  [ 'POINTZ EMPTY',           'point', 1, 0, 1, [] ],
  [ 'POINT ZM EMPTY',         'point', 1, 1, 1, [] ],
  [ 'LINESTRINGM EMPTY',      'linestring', 0, 1, 1, [] ],
  [ 'POLYGON M EMPTY',        'polygon', 0, 1, 1, [] ],
  [ 'POLYGONM EMPTY',         'polygon', 0, 1, 1, [] ],
  [ 'MULTIPOINTM EMPTY',      'multipoint', 0, 1, 1, [] ],
  [ 'MULTIPOLYGON ZM EMPTY',  'multipolygon', 1, 1, 1, [] ],
  [ 'GEOMETRYCOLLECTION EMPTY',    'geometrycollection', 0, 0, 1, [] ],
  [ 'GEOMETRYCOLLECTIONM EMPTY',   'geometrycollection', 0, 1, 1, [] ],
  [ 'GEOMETRYCOLLECTION ZM EMPTY', 'geometrycollection', 1, 1, 1, [] ],
  # An empty part keeps its place, as in the EWKB decoder.
  [ 'MULTIPOINT(EMPTY,(1 2))',        'multipoint', 0, 0, 0, [[],[1,2]] ],
  [ 'MULTIPOINT(EMPTY,1 2)',          'multipoint', 0, 0, 0, [[],[1,2]] ],
  [ 'MULTIPOINT((1 2),EMPTY)',        'multipoint', 0, 0, 0, [[1,2],[]] ],
  [ 'MULTIPOINT(1 2,EMPTY,3 4)',      'multipoint', 0, 0, 0, [[1,2],[],[3,4]] ],
  [ 'MULTIPOINT(EMPTY)',              'multipoint', 0, 0, 1, [[]] ],
  [ 'MULTIPOINTM(EMPTY,1 2 3)',       'multipoint', 0, 1, 0, [[],[1,2,3]] ],
  [ 'MULTIPOINT M (EMPTY,(1 2 3))',   'multipoint', 0, 1, 0, [[],[1,2,3]] ],
  [ 'MULTILINESTRING(EMPTY,(0 0,1 1))', 'multilinestring', 0, 0, 0, [[],[[0,0],[1,1]]] ],
  [ 'MULTILINESTRING((0 0,1 1),EMPTY)', 'multilinestring', 0, 0, 0, [[[0,0],[1,1]],[]] ],
  [ 'MULTILINESTRING(EMPTY)',         'multilinestring', 0, 0, 1, [[]] ],
  [ 'MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))', 'multipolygon', 0, 0, 0, [[],[$TRI]] ],
  [ 'MULTIPOLYGON(((0 0,1 0,1 1,0 0)),EMPTY)', 'multipolygon', 0, 0, 0, [[$TRI],[]] ],
  [ 'MULTIPOLYGON(EMPTY)',            'multipolygon', 0, 0, 1, [[]] ],
  [ 'MULTIPOLYGON(((0 0,1 0,1 1,0 0)),EMPTY,((0 0,1 0,1 1,0 0),(0 0,1 0,1 1,0 0)))',
    'multipolygon', 0, 0, 0, [[$TRI],[],[$TRI,$TRI]] ],
  [ 'MULTIPOLYGON EMPTY',             'multipolygon', 0, 0, 1, [] ],
  # GEOMETRYCOLLECTION: a list of { type, coords, is_empty }, as the decoder
  [ 'GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 'geometrycollection', 0, 0, 0, [
      { type => 'point', coords => [1,2], is_empty => 0 },
      { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION( POINT(1 2) , POLYGON((0 0,1 0,1 1,0 0)) )', 'geometrycollection', 0, 0, 0, [
      { type => 'point', coords => [1,2], is_empty => 0 },
      { type => 'polygon', coords => [$TRI], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION(POINT(1 2 3))', 'geometrycollection', 1, 0, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION(POINT(1 2 3 4))', 'geometrycollection', 1, 1, 0, [
      { type => 'point', coords => [1,2,3,4], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION Z (POINT Z (1 2 3),LINESTRING Z (0 0 1,1 1 2))', 'geometrycollection', 1, 0, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 },
      { type => 'linestring', coords => [[0,0,1],[1,1,2]], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION Z(POINT(1 2 3))', 'geometrycollection', 1, 0, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTIONM(POINTM(1 2 3))', 'geometrycollection', 0, 1, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION M (POINT M (1 2 3))', 'geometrycollection', 0, 1, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 } ] ],
  # unmarked collection, marked member: PostGIS takes the member's dimension
  [ 'GEOMETRYCOLLECTION(POINT M(1 2 3))', 'geometrycollection', 0, 1, 0, [
      { type => 'point', coords => [1,2,3], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION ZM (POINT ZM (1 2 3 4))', 'geometrycollection', 1, 1, 0, [
      { type => 'point', coords => [1,2,3,4], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION(POINT EMPTY,LINESTRING(0 0,1 1))', 'geometrycollection', 0, 0, 0, [
      { type => 'point', coords => [], is_empty => 1 },
      { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION(POINT EMPTY,POLYGON EMPTY)', 'geometrycollection', 0, 0, 1, [
      { type => 'point', coords => [], is_empty => 1 },
      { type => 'polygon', coords => [], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTION(POINT Z EMPTY)', 'geometrycollection', 1, 0, 1, [
      { type => 'point', coords => [], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTIONM(POINTM EMPTY)', 'geometrycollection', 0, 1, 1, [
      { type => 'point', coords => [], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTION Z(POINT EMPTY)', 'geometrycollection', 1, 0, 1, [
      { type => 'point', coords => [], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTION(MULTIPOINT(EMPTY,1 2),POINT EMPTY)', 'geometrycollection', 0, 0, 0, [
      { type => 'multipoint', coords => [[],[1,2]], is_empty => 0 },
      { type => 'point', coords => [], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTION(MULTIPOINT(EMPTY))', 'geometrycollection', 0, 0, 1, [
      { type => 'multipoint', coords => [[]], is_empty => 1 } ] ],
  [ 'GEOMETRYCOLLECTION(MULTIPOINT((1 2),(3 4)),MULTILINESTRING((0 0,1 1),(2 2,3 3)),MULTIPOLYGON(((0 0,1 0,1 1,0 0))))',
    'geometrycollection', 0, 0, 0, [
      { type => 'multipoint', coords => [[1,2],[3,4]], is_empty => 0 },
      { type => 'multilinestring', coords => [[[0,0],[1,1]],[[2,2],[3,3]]], is_empty => 0 },
      { type => 'multipolygon', coords => [[$TRI]], is_empty => 0 } ] ],
  # a collection in a collection
  [ 'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))', 'geometrycollection', 0, 0, 0, [
      { type => 'geometrycollection', is_empty => 0,
        coords => [ { type => 'point', coords => [1,2], is_empty => 0 } ] },
      { type => 'point', coords => [3,4], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTIONM(GEOMETRYCOLLECTIONM(POINTM(1 2 3)),POINTM(3 4 5))', 'geometrycollection', 0, 1, 0, [
      { type => 'geometrycollection', is_empty => 0,
        coords => [ { type => 'point', coords => [1,2,3], is_empty => 0 } ] },
      { type => 'point', coords => [3,4,5], is_empty => 0 } ] ],
  [ 'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION EMPTY)', 'geometrycollection', 0, 0, 1, [
      { type => 'geometrycollection', coords => [], is_empty => 1 } ] ],
);

use DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;
my $builder = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder';

for my $form (@forms) {
  my ($wkt, $type, $z, $m, $empty, $coords) = @$form;
  my $r = $p->parse($wkt);
  unless ($r) { fail "$wkt is read"; next }
  is $r->{type},     $type, "$wkt: type";
  is $r->{has_z},    $z,    "$wkt: has_z";
  is $r->{has_m},    $m,    "$wkt: has_m";
  is $r->{is_empty}, $empty, "$wkt: is_empty";
  is_deeply $r->{coords}, $coords, "$wkt: coords";

  # What the builder makes of it is read as the same thing.
  my $again = $p->parse($builder->build($r));
  is_deeply $again, $r, "$wkt: built and read again, the same";
}

# A word that is not a type, with or without a marker, is no geometry.
is $p->parse('POINTX(1 2)'),     undef, 'POINTX is no type';
is $p->parse('POINTMM(1 2 3)'),  undef, 'POINTMM is no type';
is $p->parse('CIRCULARSTRINGM(0 0 1,1 1 2,2 0 3)'), undef, 'a curve is not read';
is $p->parse('GEOMETRYCOLLECTION(CIRCULARSTRING(0 0,1 1,2 0))'), undef,
  'a collection with a member that is not read is not read';
is $p->parse('GEOMETRYCOLLECTION(POINT(1 2)'), undef, 'unbalanced collection';

# Nesting of collections is limited to 32 levels; deeper input throws before
# the parser has spent time or memory on it.
sub nested { my $d = shift; ('GEOMETRYCOLLECTION(' x $d) . 'POINT(1 1)' . (')' x $d) }

{
  my $started = time;
  my $r = eval { $p->parse(nested(2000)); 1 };
  my $err = $@;
  ok !$r, 'depth 2000 throws';
  like "$err", qr/WKT nesting too deep/, '... naming the limit';
  unlike "$err", qr/POINT|GEOMETRYCOLLECTION/, '... without the input in the message';
  cmp_ok time - $started, '<', 2, '... fast';
}

{
  my $r = $p->parse(nested(32));
  ok $r, 'depth 32 parses';
  my $depth = 0;
  my $g = $r;
  while ($g->{type} eq 'geometrycollection') { $depth++; $g = $g->{coords}[0] }
  is $depth, 32, '... all 32 levels are there';
  is_deeply $g, { type => 'point', coords => [1, 1], is_empty => 0 }, '... down to the point';

  my $ok = eval { $p->parse(nested(33)); 1 };
  ok !$ok, 'depth 33 throws';
  like "$@", qr/WKT nesting too deep/, '... naming the limit';
}

# Wide input costs time in proportion to its length.
{
  my $started = time;
  my $r = $p->parse('MULTIPOINT(' . join(',', map { "($_ 1)" } 1 .. 200_000) . ')');
  is scalar @{ $r->{coords} }, 200_000, 'MULTIPOINT with 200000 points';
  is_deeply $r->{coords}[199_999], [200_000, 1], '... the last one is read';
  cmp_ok time - $started, '<', 10, '... in linear time';

  $started = time;
  $r = $p->parse('GEOMETRYCOLLECTION(' . join(',', ('POINT(1 2)') x 100_000) . ')');
  is scalar @{ $r->{coords} }, 100_000, 'GEOMETRYCOLLECTION with 100000 members';
  cmp_ok time - $started, '<', 10, '... in linear time';
}

# A long run of whitespace is read in linear time, wherever it stands.
{
  my $w = ' ' x 1_000_000;
  for my $case (
    ['between ordinates',    "POINT(1${w}2)"],
    ['before a comma',       "LINESTRING(1 2${w},3 4)"],
    ['after a comma',        "LINESTRING(1 2,${w}3 4)"],
    ['around a ring',        "POLYGON((${w}0 0${w},1 0,1 1,0 0${w}))"],
    ['in a MULTIPOINT',      "MULTIPOINT((1${w}2)${w},(3 4))"],
  ) {
    my ($name, $wkt) = @$case;
    my $started = time;
    my $r = $p->parse($wkt);
    my $took = time - $started;
    ok $r, "1 MB of whitespace $name: read";
    cmp_ok $took, '<', 0.5, '... in linear time';
  }
}

# Ordinates are numbers, two to four per point; a point list has no empty entry.
for my $wkt ('POINT(abc def)', 'POINT((1 1))', 'POINT(1 2 3 4 5 6)', 'POINT(1 2 3 4 5)',
             'POINT(1)', 'POINT(1 x)', 'POINT(1 2e)', 'POINT(1 --2)', 'POINT(0x10 1)',
             'POINT(Inf NaN)', 'POINT(1e9999 0)', 'POINT(0 -1e9999)', 'POINT(. 1)', 'LINESTRING(0 0,1)',
             'POLYGON((0 0,1 0,1 abc,0 0))', 'MULTIPOINT(1 2,3)', 'MULTIPOINT((1 2),(3 x))',
             'MULTILINESTRING((0 0,1 1),(2 2,3 q))', 'MULTIPOLYGON(((0 0,1 0,1 1,z 0)))',
             'LINESTRING(1 2,)', 'LINESTRING(0 0,1 1,)', 'LINESTRING(,0 0,1 1)', 'LINESTRING(0 0,,1 1)',
             'GEOMETRYCOLLECTION(POINT(a b))') {
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  is $p->parse($wkt), undef, "$wkt: not read";
  is scalar @warn, 0, '... without a warning';
}

for my $case (['1e5', 1e5], ['-.5', -0.5], ['3.', 3], ['1E-3', 0.001], ['+1', undef],
              ['2.5e+2', 250], ['-0', 0], ['.5E3', 500]) {
  my ($tok, $want) = @$case;
  my $r = $p->parse("POINT($tok 1)");
  if (defined $want) {
    is $r && $r->{coords}[0], $want, "POINT($tok 1): $tok is read";
  } else {
    is $r, undef, "POINT($tok 1): a leading plus is not WKT";
  }
}
is_deeply $p->parse('LINESTRING(1e0 -.5 3.,0 0 0)')->{coords}, [[1, -0.5, 3], [0, 0, 0]],
  'numbers of the several forms in one list';

done_testing;
