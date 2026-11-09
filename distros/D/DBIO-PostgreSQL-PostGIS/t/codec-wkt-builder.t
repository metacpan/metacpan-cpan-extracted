use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder;
my $b = 'DBIO::PostgreSQL::PostGIS::Codec::WKT::Builder';

is $b->build({ type => 'point',      coords => [13.4, 52.5] }),
   'POINT(13.4 52.5)',  'POINT build';

is $b->build({ type => 'point',      coords => [13.4, 52.5, 10], has_z => 1 }),
   'POINT Z(13.4 52.5 10)', 'POINT Z build';

is $b->build({ type => 'linestring', coords => [[0,0],[1,1],[2,2]] }),
   'LINESTRING(0 0,1 1,2 2)', 'LINESTRING build';

is $b->build({ type => 'polygon',    coords => [[[0,0],[10,0],[10,10],[0,10],[0,0]]] }),
   'POLYGON((0 0,10 0,10 10,0 10,0 0))', 'POLYGON build';

is $b->build({ type => 'point', is_empty => 1 }),
   'POINT EMPTY', 'EMPTY build';

# Round-trip with Parser
use DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser;
my $wkt = 'POLYGON((0 0,10 0,10 10,0 10,0 0),(1 1,2 1,2 2,1 2,1 1))';
my $parsed  = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($wkt);
my $rebuilt = $b->build($parsed);
is $rebuilt, $wkt, 'round-trip POLYGON with hole';

# The dimension marker is a word of its own: PostGIS reads "POINT M(...)"
# and so does this dist's parser, which reads "POINTM(...)", the form
# ST_AsEWKT prints, as well (karr k14, k21).
is $b->build({ type => 'point', coords => [1, 2, 9], has_m => 1 }),
   'POINT M(1 2 9)', 'POINT M build';

is $b->build({ type => 'point', coords => [1, 2, 3, 4], has_z => 1, has_m => 1 }),
   'POINT ZM(1 2 3 4)', 'POINT ZM build';

is $b->build({ type => 'point', is_empty => 1, has_m => 1 }),
   'POINT M EMPTY', 'M EMPTY build';

# MULTIPOINT is written without parentheses around each point.
is $b->build({ type => 'multipoint', coords => [[1,2],[3,4],[5,6]] }),
   'MULTIPOINT(1 2,3 4,5 6)', 'MULTIPOINT build';

# What the builder writes, the parser reads back: same type, same
# coordinates, same flags.
for my $in (
  { type => 'multipoint', coords => [[1,2],[3,4],[5,6]] },
  { type => 'multipoint', coords => [[1,2,3],[4,5,6]], has_z => 1 },
  { type => 'multipoint', coords => [[1,2,9],[3,4,8]], has_m => 1 },
  { type => 'point',      coords => [1,2,3],           has_z => 1 },
  { type => 'point',      coords => [1,2,9],           has_m => 1 },
  { type => 'point',      coords => [1,2,3,4],         has_z => 1, has_m => 1 },
  { type => 'linestring', coords => [[0,0,5],[1,1,6]], has_m => 1 },
) {
  my $built = $b->build($in);
  my $out   = DBIO::PostgreSQL::PostGIS::Codec::WKT::Parser->parse($built);
  ok $out, "$built parses" or next;
  is $out->{type}, $in->{type}, "$built type";
  is_deeply $out->{coords}, $in->{coords}, "$built coords";
  is $out->{has_z}, $in->{has_z} ? 1 : 0, "$built has_z";
  is $out->{has_m}, $in->{has_m} ? 1 : 0, "$built has_m";
}

# EMPTY, for every type and every dimension (karr k19). The builder wrote
# "LINESTRING()" for a line without points.
for my $case (
  [ { type => 'point',              is_empty => 1 },                'POINT EMPTY' ],
  [ { type => 'linestring',         is_empty => 1 },                'LINESTRING EMPTY' ],
  [ { type => 'polygon',            is_empty => 1 },                'POLYGON EMPTY' ],
  [ { type => 'multipoint',         is_empty => 1 },                'MULTIPOINT EMPTY' ],
  [ { type => 'multilinestring',    is_empty => 1 },                'MULTILINESTRING EMPTY' ],
  [ { type => 'multipolygon',       is_empty => 1 },                'MULTIPOLYGON EMPTY' ],
  [ { type => 'geometrycollection', is_empty => 1 },                'GEOMETRYCOLLECTION EMPTY' ],
  [ { type => 'linestring',         is_empty => 1, has_z => 1 },    'LINESTRING Z EMPTY' ],
  [ { type => 'polygon',            is_empty => 1, has_m => 1 },    'POLYGON M EMPTY' ],
  [ { type => 'geometrycollection', is_empty => 1, has_z => 1, has_m => 1 },
    'GEOMETRYCOLLECTION ZM EMPTY' ],
  # What the decoder returns for an empty geometry: coords [] and the flag.
  [ { type => 'point',      coords => [], is_empty => 1 },          'POINT EMPTY' ],
  [ { type => 'linestring', coords => [], is_empty => 1 },          'LINESTRING EMPTY' ],
  [ { type => 'multipolygon', coords => [], is_empty => 1, has_z => 1 },
    'MULTIPOLYGON Z EMPTY' ],
  # Without the flag, an empty list of parts is still empty, not "()".
  [ { type => 'linestring', coords => [] },                         'LINESTRING EMPTY' ],
  [ { type => 'polygon',    coords => [] },                         'POLYGON EMPTY' ],
) {
  my ($in, $want) = @$case;
  is $b->build($in), $want, "$want";
}

# An empty part keeps its place in a MULTI*: PostGIS reads and prints it
# as EMPTY. A MULTI* of nothing but empty parts is empty (ST_IsEmpty) and
# is still written with its parts: dropping them would build another
# geometry (count 0, not 1).
is $b->build({ type => 'multipoint', coords => [ [], [1,2] ] }),
   'MULTIPOINT(EMPTY,1 2)', 'MULTIPOINT with an empty point first';
is $b->build({ type => 'multipoint', coords => [ [1,2], [] ] }),
   'MULTIPOINT(1 2,EMPTY)', 'MULTIPOINT with an empty point last';
is $b->build({ type => 'multipoint', coords => [ [] ], is_empty => 1 }),
   'MULTIPOINT(EMPTY)', 'MULTIPOINT of one empty point, itself empty';
is $b->build({ type => 'multilinestring', coords => [ [], [[0,0],[1,1]] ] }),
   'MULTILINESTRING(EMPTY,(0 0,1 1))', 'MULTILINESTRING with an empty line';
is $b->build({ type => 'multipolygon', coords => [ [], [[[0,0],[1,0],[1,1],[0,0]]] ] }),
   'MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))', 'MULTIPOLYGON with an empty polygon';

# A GEOMETRYCOLLECTION is its members, each written with its own type,
# and with its own dimension marker the way ST_AsText prints them (karr k24).
my $m = sub { +{ type => $_[0], coords => $_[1], is_empty => $_[2] // 0 } };
is $b->build({ type => 'geometrycollection', coords => [
     $m->(point => [1,2]), $m->(linestring => [[0,0],[1,1]]),
   ] }),
   'GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 'GEOMETRYCOLLECTION of a point and a line';
is $b->build({ type => 'geometrycollection', has_z => 1, coords => [
     $m->(point => [1,2,3]), $m->(linestring => [[0,0,1],[1,1,2]]),
   ] }),
   'GEOMETRYCOLLECTION Z(POINT Z(1 2 3),LINESTRING Z(0 0 1,1 1 2))', 'GEOMETRYCOLLECTION Z';
is $b->build({ type => 'geometrycollection', has_m => 1, coords => [
     $m->(point => [1,2,3]),
   ] }),
   'GEOMETRYCOLLECTION M(POINT M(1 2 3))', 'GEOMETRYCOLLECTION M';
is $b->build({ type => 'geometrycollection', has_z => 1, has_m => 1, coords => [
     $m->(point => [1,2,3,4]),
   ] }),
   'GEOMETRYCOLLECTION ZM(POINT ZM(1 2 3 4))', 'GEOMETRYCOLLECTION ZM';
is $b->build({ type => 'geometrycollection', coords => [
     $m->(point => [], 1), $m->(linestring => [[0,0],[1,1]]),
   ] }),
   'GEOMETRYCOLLECTION(POINT EMPTY,LINESTRING(0 0,1 1))', 'an empty member is written EMPTY';
is $b->build({ type => 'geometrycollection', has_z => 1, coords => [ $m->(point => [], 1) ],
     is_empty => 1 }),
   'GEOMETRYCOLLECTION Z(POINT Z EMPTY)', 'a collection of an empty member is still its member';
is $b->build({ type => 'geometrycollection', coords => [
     $m->(multipoint => [[1,2],[3,4]]), $m->(polygon => [[[0,0],[1,0],[1,1],[0,0]]]),
   ] }),
   'GEOMETRYCOLLECTION(MULTIPOINT(1 2,3 4),POLYGON((0 0,1 0,1 1,0 0)))',
   'a MULTI* member and a polygon';
is $b->build({ type => 'geometrycollection', coords => [
     $m->(geometrycollection => [ $m->(point => [1,2]) ]), $m->(point => [3,4]),
   ] }),
   'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))', 'a collection in a collection';
is $b->build({ type => 'geometrycollection', has_m => 1, coords => [
     $m->(geometrycollection => [ $m->(point => [1,2,3]) ]),
   ] }),
   'GEOMETRYCOLLECTION M(GEOMETRYCOLLECTION M(POINT M(1 2 3)))', 'the dimension reaches a nested collection';

done_testing;
