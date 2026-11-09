use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;
my $d = 'DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder';

# Build EWKB hex for POINT(1.0, 2.0) SRID=4326 in little-endian
# byte_order=1(LE), type=0x20000001(POINT|SRID_FLAG), srid=4326, x=1.0, y=2.0
my $hex = unpack('H*', pack('C V V d< d<', 1, 0x20000001, 4326, 1.0, 2.0));

my $r = $d->decode_hex($hex);
is $r->{type},     'point', 'type is point';
is $r->{srid},     4326,    'SRID is 4326';
is $r->{coords}[0], 1.0,   'X = 1.0';
is $r->{coords}[1], 2.0,   'Y = 2.0';

# Without SRID
my $hex2 = unpack('H*', pack('C V d< d<', 1, 1, 3.0, 4.0));
my $r2   = $d->decode_hex($hex2);
is $r2->{type},    'point', 'type is point';
is $r2->{srid},    undef,   'no SRID';
is $r2->{coords}[0], 3.0,  'X = 3.0';

# A geometry column may hold more types than this decoder decodes: the
# curve types, POLYHEDRALSURFACE, TIN, TRIANGLE (karr k15). The decoder
# used to read every type it had no branch for as "a count, then that
# many member geometries" -- bytes that are no such thing. What came out
# was either an underrun or coordinates that were never in the value
# (TRIANGLE gave [[]]). A type that is not decoded has to be named and
# left alone: the caller keeps the hex, and nothing is made up.
#
# The hex strings are the ones a PostGIS 3.6 server sends for
# ST_GeomFromText(<wkt>, 4326); t/34-undecoded-live.t holds the type
# names against a live server.
my @undecoded = (
  [ circularstring => 'CIRCULARSTRING(0 0,1 1,2 0)', 0,
    '0108000020E61000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000' ],
  [ compoundcurve => 'COMPOUNDCURVE(CIRCULARSTRING(0 0,1 1,2 0),(2 0,3 0))', 0,
    '0109000020E61000000200000001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000004000000000000000000102000000020000000000000000000040000000000000000000000000000008400000000000000000' ],
  [ curvepolygon => 'CURVEPOLYGON(CIRCULARSTRING(0 0,4 0,4 4,0 4,0 0))', 0,
    '010A000020E6100000010000000108000000050000000000000000000000000000000000000000000000000010400000000000000000000000000000104000000000000010400000000000000000000000000000104000000000000000000000000000000000' ],
  [ multicurve => 'MULTICURVE((0 0,5 5),CIRCULARSTRING(4 0,4 4,8 4))', 0,
    '010B000020E6100000020000000102000000020000000000000000000000000000000000000000000000000014400000000000001440010800000003000000000000000000104000000000000000000000000000001040000000000000104000000000000020400000000000001040' ],
  [ multisurface => 'MULTISURFACE(CURVEPOLYGON(CIRCULARSTRING(0 0,4 0,4 4,0 4,0 0)))', 0,
    '010C000020E610000001000000010A000000010000000108000000050000000000000000000000000000000000000000000000000010400000000000000000000000000000104000000000000010400000000000000000000000000000104000000000000000000000000000000000' ],
  [ polyhedralsurface => 'POLYHEDRALSURFACE(((0 0 0,0 0 1,0 1 1,0 0 0)))', 1,
    '010F0000A0E6100000010000000103000080010000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F000000000000000000000000000000000000000000000000' ],
  [ tin => 'TIN(((0 0 0,0 0 1,0 1 0,0 0 0)))', 1,
    '01100000A0E6100000010000000111000080010000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F0000000000000000000000000000000000000000000000000000000000000000' ],
  [ triangle => 'TRIANGLE((0 0,0 9,9 0,0 0))', 0,
    '0111000020E6100000010000000400000000000000000000000000000000000000000000000000000000000000000022400000000000002240000000000000000000000000000000000000000000000000' ],
);

for my $case (@undecoded) {
  my ($type, $wkt, $has_z, $ewkb) = @$case;
  subtest "a type that is not decoded: $wkt" => sub {
    my $got = eval { $d->decode_hex($ewkb) };
    ok $got, 'decode_hex answers' or diag $@ or return;
    is $got->{type},  $type,  'the type is named';
    is $got->{srid},  4326,   'the SRID of the header';
    is $got->{has_z}, $has_z, 'the Z flag of the header';
    is $got->{has_m}, 0,      'the M flag of the header';
    ok exists $got->{coords}, 'coords is in the answer ...';
    is $got->{coords}, undef, '... and is undef: nothing was decoded'
      or diag explain $got->{coords};
  };
}

my $SRID = 0x20000000;
my $head   = sub { pack 'C V', 1, $_[0] };
my $point  = sub { pack 'd<*', @_ };
my $line   = sub { pack('V', scalar @_) . join '', map { $point->(@$_) } @_ };
my $hex_of = sub { unpack 'H*', join '', @_ };
my $dec    = sub { my $r = eval { $d->decode_hex($_[0]) }; diag $@ unless $r; $r || {} };

# The same holds one level down. A GEOMETRYCOLLECTION may hold any type,
# so it may hold one that is not decoded; the members before it would
# decode, but a collection with a hole in it is not the value. The whole
# is then not decoded, and it keeps the type of the whole.
subtest 'a collection that holds a type that is not decoded' => sub {
  # GEOMETRYCOLLECTION(POINT(1 2),CIRCULARSTRING(0 0,1 1,2 0)), SRID 4326,
  # as the server sends it.
  my $got = eval { $d->decode_hex(
    '0107000020E6100000020000000101000000000000000000F03F000000000000004001080000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000'
  ) };
  ok $got, 'decode_hex answers' or diag $@ or return;
  is $got->{type},   'geometrycollection', 'the type of the collection';
  is $got->{srid},   4326,  'the SRID of the header';
  is $got->{coords}, undef, 'no coordinates, not those of the point alone'
    or diag explain $got->{coords};

  # ... however deep: GEOMETRYCOLLECTION(POINT(1 2),
  # GEOMETRYCOLLECTION(TRIANGLE((0 0,0 9,9 0,0 0))))
  my $nested = eval { $d->decode_hex(
    '0107000020E6100000020000000101000000000000000000F03F00000000000000400107000000010000000111000000010000000400000000000000000000000000000000000000000000000000000000000000000022400000000000002240000000000000000000000000000000000000000000000000'
  ) };
  ok $nested, 'decode_hex answers for a nested collection' or diag $@ or return;
  is $nested->{type},   'geometrycollection', 'the type of the outer collection';
  is $nested->{coords}, undef, 'no coordinates for a nested one either'
    or diag explain $nested->{coords};
};

# CHANGED (karr k24): a collection of types the decoder knows is still
# decoded, but its coords are no longer the bare coordinates of the
# members. A member is {type, coords, is_empty}: without its type the
# members cannot be told apart (a point [1,2] and a two-point line's first
# point look alike) and no valid WKT can be built from them.
subtest 'a collection of decoded types is still decoded' => sub {
  my $got = $d->decode_hex($hex_of->(
    $head->(7 | $SRID), pack('V', 4326), pack('V', 2),
    $head->(1), $point->(1, 2),
    $head->(2), $line->([0,0],[1,1]),
  ));
  is $got->{type}, 'geometrycollection', 'type';
  is_deeply $got->{coords}, [
    { type => 'point',      coords => [1,2],         is_empty => 0 },
    { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 },
  ], 'the members, each with its type (CHANGED from bare coordinates, karr k24)';
  is $got->{is_empty}, 0, 'not empty';
};

# A type id PostGIS does not write has no name; the header is read all
# the same, and the body is not guessed at.
subtest 'a type id without a name' => sub {
  my $got = eval { $d->decode_hex($hex_of->(
    $head->(99 | $SRID), pack('V', 4326), $point->(1, 2),
  )) };
  ok $got, 'decode_hex answers' or diag $@ or return;
  is $got->{type},   undef, 'no type name';
  is $got->{srid},   4326,  'the SRID of the header';
  is $got->{coords}, undef, 'no coordinates' or diag explain $got->{coords};
};

# A MULTIPOINT holds points and nothing else (PostGIS: "MultiPoint cannot
# contain LineString element"). Its member used to be read as whatever
# its type word said, and the line came out as a "point" of two points.
# That is not a type left undecoded, it is broken input, and it throws.
subtest 'a MULTI* whose member is of another type is refused' => sub {
  my %bad = (
    'MULTIPOINT holding a LINESTRING' => $hex_of->(
      $head->(4), pack('V', 1), $head->(2), $line->([0,0],[1,1])),
    'MULTILINESTRING holding a POINT' => $hex_of->(
      $head->(5), pack('V', 1), $head->(1), $point->(1, 2)),
    'MULTIPOLYGON holding a CIRCULARSTRING' => $hex_of->(
      $head->(6), pack('V', 1), $head->(8), $line->([0,0],[1,1],[2,0])),
  );
  for my $name (sort keys %bad) {
    my $got = eval { $d->decode_hex($bad{$name}) };
    is $got, undef, "$name: no answer" or diag explain $got;
    like $@, qr/decode_hex: .*member/, "$name: the error names the member";
  }
};

# decode_header reads what stands before the body and stops there. It is
# what is left to say about a value whose body cannot be read: the type
# and the SRID it claims to have.
subtest 'decode_header' => sub {
  is_deeply $d->decode_header($hex),
    { type => 'point', srid => 4326, has_z => 0, has_m => 0 },
    'of a point with an SRID';
  is_deeply $d->decode_header($hex2),
    { type => 'point', srid => undef, has_z => 0, has_m => 0 },
    'of a point without one';
  is_deeply $d->decode_header($undecoded[5][3]),
    { type => 'polyhedralsurface', srid => 4326, has_z => 1, has_m => 0 },
    'of a type that is not decoded';

  # Cut off after the first ordinate: the body is unreadable, and
  # decode_hex says so; the header is all there.
  my $cut  = substr $hex, 0, 34;
  my $body = eval { $d->decode_hex($cut) };
  is $body, undef, 'decode_hex refuses a cut-off point';
  like $@, qr/decode_hex: underrun/, '... as an underrun';
  my $header = eval { $d->decode_header($cut) };
  is_deeply $header,
    { type => 'point', srid => 4326, has_z => 0, has_m => 0 },
    'decode_header still reads its header' or diag $@;

  # Nothing to read a header from.
  $header = eval { $d->decode_header('02' . substr $hex, 2) };
  is $header, undef, 'decode_header refuses a byte order that is none';
  like $@, qr/invalid byte_order/, '... naming it';
  $header = eval { $d->decode_header('0101') };
  is $header, undef, 'decode_header refuses a header that is cut off';
  like $@, qr/underrun/, '... as an underrun';
};

# A count is four bytes of input like any other, and a broken value can
# claim any number of points. Reading that many was tried before the
# input was looked at: a line claiming 0xFFFFFFFF points took the process
# down with "Out of memory", which no eval catches. A count the rest of
# the input cannot hold is refused before anything is sized by it. (The
# count here is small on purpose -- with the check gone this test fails
# on the message, it does not eat the machine.)
subtest 'a count the input cannot hold is refused before it is used' => sub {
  my %claims = (
    'points of a line'        => $hex_of->($head->(2), pack('V', 100_000), $point->(1, 2)),
    'rings of a polygon'      => $hex_of->($head->(3), pack('V', 100_000), pack('V', 0)),
    'points of a ring'        => $hex_of->($head->(3), pack('V', 1), pack('V', 100_000), $point->(1, 2)),
    'members of a multipoint' => $hex_of->($head->(4), pack('V', 100_000), $head->(1), $point->(1, 2)),
    'members of a collection' => $hex_of->($head->(7), pack('V', 100_000), $head->(1), $point->(1, 2)),
  );
  for my $name (sort keys %claims) {
    my $got = eval { $d->decode_hex($claims{$name}) };
    is $got, undef, "$name: refused";
    like $@, qr/decode_hex: underrun at pos \d+ \(need \d{6,}, /,
      "$name: for the size the count asks for, not for one item";
  }
};

# ---------------------------------------------------------------------
# Input that is no clean EWKB (karr k18, k25). The decoder took what
# PostGIS never sends without a word. The server was asked what it does
# with each of these (ST_GeomFromEWKB, PostGIS 3.6); the decoder follows
# it where being strict does no harm, and is stricter where the server
# is lenient: a value read from a database is clean, so anything else is
# a broken value and says so.

# Hex that is no hex: pack('H*') filled a lone nibble with zero and read
# any other character as a digit, so the ordinates came out shifted or
# made up. (k18)
subtest 'hex that is no hex is refused' => sub {
  my %bad = (
    'odd length'          => substr($hex, 0, -1),
    'odd length, no SRID' => substr($hex2, 0, -1),
    'a non-hex character' => substr($hex, 0, 10) . 'G' . substr($hex, 11),
    'a space'             => $hex . ' ',
    'a 0x prefix'         => '0x' . $hex,
  );
  for my $name (sort keys %bad) {
    for my $method (qw(decode_hex decode_header)) {
      my $got = eval { $d->$method($bad{$name}) };
      is $got, undef, "$name: $method gives no answer" or diag explain $got;
      like $@, qr/decode_hex: .*hex/, "$name: $method names the hex"
        or diag $@;
    }
  }
  # Upper and lower case digits are both hex.
  is_deeply $d->decode_hex(lc $hex)->{coords}, [1, 2], 'lower case is hex';
  is_deeply $d->decode_hex(uc $hex)->{coords}, [1, 2], 'upper case is hex';
};

# Geometry->from_ewkb_hex takes the refusal and keeps the string (k15):
# an object carrying the hex, without coordinates.
subtest 'from_ewkb_hex keeps a hex the decoder refuses' => sub {
  require DBIO::PostgreSQL::PostGIS::Geometry;
  my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';
  for my $bad (substr($hex, 0, -1), $hex . '00', substr($hex, 0, 10) . 'G' . substr($hex, 11)) {
    my $g = $G->from_ewkb_hex($bad);
    isa_ok $g, $G, 'an object for ' . substr($bad, 0, 12) . '...' or next;
    is $g->ewkb_hex, $bad, 'it carries the hex';
    is $g->coordinates, undef, 'and no coordinates';
  }
};

# Bytes behind the end of the geometry: the server ignores them, a value
# it sends has none. Reading them as part of the value would be a guess.
subtest 'bytes behind the geometry are refused' => sub {
  my %bad = (
    'after a point'      => $hex . '00',
    'after a line'       => $hex_of->($head->(2), $line->([0,0],[1,1]), "\0"),
    'after a multipoint' => $hex_of->($head->(4), pack('V', 1), $head->(1), $point->(1, 2), "\0\0"),
  );
  for my $name (sort keys %bad) {
    my $got = eval { $d->decode_hex($bad{$name}) };
    is $got, undef, "$name: no answer" or diag explain $got;
    like $@, qr/decode_hex: trailing bytes/, "$name: the error says so" or diag $@;
  }
  # An undecoded body is not read, so its end is not known: nothing to check.
  ok eval { $d->decode_hex($undecoded[0][3] . '00') }, 'an undecoded body has no known end';
  # decode_header reads the header and stops: it says nothing about the rest.
  ok eval { $d->decode_header($bad{'after a point'}) }, 'decode_header does not look behind the header';
};

# Big-endian EWKB, as ST_AsEWKB(geom, 'XDR') writes it (PostGIS 3.6,
# SRID=4326). The decoder read these, but nothing held it.
subtest 'big-endian EWKB' => sub {
  my @cases = (
    [ 'POINT(1 2)', 'point', [1,2], 0, 0,
      '0020000001000010e63ff00000000000004000000000000000' ],
    [ 'POINT ZM (1 2 3 4)', 'point', [1,2,3,4], 1, 1,
      '00e0000001000010e63ff0000000000000400000000000000040080000000000004010000000000000' ],
    [ 'LINESTRING(0 0,1 1)', 'linestring', [[0,0],[1,1]], 0, 0,
      '0020000002000010e600000002000000000000000000000000000000003ff00000000000003ff0000000000000' ],
    [ 'POLYGON((0 0,1 0,1 1,0 0))', 'polygon', [[[0,0],[1,0],[1,1],[0,0]]], 0, 0,
      '0020000003000010e60000000100000004000000000000000000000000000000003ff000000000000000000000000000003ff00000000000003ff000000000000000000000000000000000000000000000' ],
    [ 'MULTIPOINT((1 2),(3 4))', 'multipoint', [[1,2],[3,4]], 0, 0,
      '0020000004000010e60000000200000000013ff00000000000004000000000000000000000000140080000000000004010000000000000' ],
    [ 'MULTIPOINT Z ((1 2 3),(4 5 6))', 'multipoint', [[1,2,3],[4,5,6]], 1, 0,
      '00a0000004000010e60000000200800000013ff0000000000000400000000000000040080000000000000080000001401000000000000040140000000000004018000000000000' ],
    [ 'MULTILINESTRING((0 0,1 1))', 'multilinestring', [[[0,0],[1,1]]], 0, 0,
      '0020000005000010e600000001000000000200000002000000000000000000000000000000003ff00000000000003ff0000000000000' ],
    [ 'MULTIPOLYGON(((0 0,1 0,1 1,0 0)))', 'multipolygon', [[[[0,0],[1,0],[1,1],[0,0]]]], 0, 0,
      '0020000006000010e60000000100000000030000000100000004000000000000000000000000000000003ff000000000000000000000000000003ff00000000000003ff000000000000000000000000000000000000000000000' ],
    [ 'GEOMETRYCOLLECTION(POINT(1 2),LINESTRING(0 0,1 1))', 'geometrycollection',
      [ { type => 'point', coords => [1,2], is_empty => 0 },
        { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 } ], 0, 0,
      '0020000007000010e60000000200000000013ff00000000000004000000000000000000000000200000002000000000000000000000000000000003ff00000000000003ff0000000000000' ],
    [ 'GEOMETRYCOLLECTION M (POINT M (1 2 3),LINESTRING M (0 0 1,1 1 2))', 'geometrycollection',
      [ { type => 'point', coords => [1,2,3], is_empty => 0 },
        { type => 'linestring', coords => [[0,0,1],[1,1,2]], is_empty => 0 } ], 0, 1,
      '0060000007000010e60000000200400000013ff000000000000040000000000000004008000000000000004000000200000002000000000000000000000000000000003ff00000000000003ff00000000000003ff00000000000004000000000000000' ],
  );
  for my $c (@cases) {
    my ($wkt, $type, $coords, $z, $m, $ewkb) = @$c;
    my $got = eval { $d->decode_hex($ewkb) };
    ok $got, "$wkt: decodes" or diag $@ or next;
    is $got->{type}, $type, "$wkt: type";
    is $got->{srid}, 4326,  "$wkt: SRID";
    is $got->{has_z}, $z,   "$wkt: Z flag";
    is $got->{has_m}, $m,   "$wkt: M flag";
    is_deeply $got->{coords}, $coords, "$wkt: coordinates";
  }
};

# M and ZM variants of the types that are named and not decoded. The
# header flags are read; the body is left alone. ST_AsHEXEWKB, PostGIS 3.6.
subtest 'M and ZM variants of the types that are not decoded' => sub {
  my @m = (
    [ circularstring => 'CIRCULARSTRING M (0 0 5,1 1 6,2 0 7)', 0, 1,
      '0108000060E610000003000000000000000000000000000000000000000000000000001440000000000000F03F000000000000F03F0000000000001840000000000000004000000000000000000000000000001C40' ],
    [ circularstring => 'CIRCULARSTRING ZM (0 0 1 5,1 1 1 6,2 0 1 7)', 1, 1,
      '01080000E0E61000000300000000000000000000000000000000000000000000000000F03F0000000000001440000000000000F03F000000000000F03F000000000000F03F000000000000184000000000000000400000000000000000000000000000F03F0000000000001C40' ],
    [ compoundcurve => 'COMPOUNDCURVE M ((0 0 1,1 1 2))', 0, 1,
      '0109000060E61000000100000001020000400200000000000000000000000000000000000000000000000000F03F000000000000F03F000000000000F03F0000000000000040' ],
    [ curvepolygon => 'CURVEPOLYGON M (CIRCULARSTRING M (0 0 1,4 0 1,4 4 1,0 4 1,0 0 1))', 0, 1,
      '010A000060E61000000100000001080000400500000000000000000000000000000000000000000000000000F03F00000000000010400000000000000000000000000000F03F00000000000010400000000000001040000000000000F03F00000000000000000000000000001040000000000000F03F00000000000000000000000000000000000000000000F03F' ],
    [ multicurve => 'MULTICURVE M ((0 0 1,5 5 2))', 0, 1,
      '010B000060E61000000100000001020000400200000000000000000000000000000000000000000000000000F03F000000000000144000000000000014400000000000000040' ],
    [ multisurface => 'MULTISURFACE M (CURVEPOLYGON M (CIRCULARSTRING M (0 0 1,4 0 1,4 4 1,0 4 1,0 0 1)))', 0, 1,
      '010C000060E610000001000000010A0000400100000001080000400500000000000000000000000000000000000000000000000000F03F00000000000010400000000000000000000000000000F03F00000000000010400000000000001040000000000000F03F00000000000000000000000000001040000000000000F03F00000000000000000000000000000000000000000000F03F' ],
    [ polyhedralsurface => 'POLYHEDRALSURFACE M (((0 0 0,0 0 1,0 1 1,0 0 0)))', 0, 1,
      '010F000060E6100000010000000103000040010000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F000000000000F03F000000000000000000000000000000000000000000000000' ],
    [ polyhedralsurface => 'POLYHEDRALSURFACE ZM (((0 0 0 1,0 0 1 1,0 1 1 1,0 0 0 1)))', 1, 1,
      '010F0000E0E61000000100000001030000C00100000004000000000000000000000000000000000000000000000000000000000000000000F03F00000000000000000000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F000000000000F03F000000000000F03F000000000000000000000000000000000000000000000000000000000000F03F' ],
    [ tin => 'TIN M (((0 0 0,0 0 1,0 1 0,0 0 0)))', 0, 1,
      '0110000060E6100000010000000111000040010000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F03F0000000000000000000000000000F03F0000000000000000000000000000000000000000000000000000000000000000' ],
    [ tin => 'TIN ZM (((0 0 0 1,0 0 1 1,0 1 0 1,0 0 0 1)))', 1, 1,
      '01100000E0E61000000100000001110000C00100000004000000000000000000000000000000000000000000000000000000000000000000F03F00000000000000000000000000000000000000000000F03F000000000000F03F0000000000000000000000000000F03F0000000000000000000000000000F03F000000000000000000000000000000000000000000000000000000000000F03F' ],
    [ triangle => 'TRIANGLE M ((0 0 1,0 9 1,9 0 1,0 0 1))', 0, 1,
      '0111000060E6100000010000000400000000000000000000000000000000000000000000000000F03F00000000000000000000000000002240000000000000F03F00000000000022400000000000000000000000000000F03F00000000000000000000000000000000000000000000F03F' ],
    [ triangle => 'TRIANGLE ZM ((0 0 0 1,0 9 0 1,9 0 0 1,0 0 0 1))', 1, 1,
      '01110000E0E61000000100000004000000000000000000000000000000000000000000000000000000000000000000F03F000000000000000000000000000022400000000000000000000000000000F03F000000000000224000000000000000000000000000000000000000000000F03F000000000000000000000000000000000000000000000000000000000000F03F' ],
  );
  for my $c (@m) {
    my ($type, $wkt, $z, $m, $ewkb) = @$c;
    my $got = eval { $d->decode_hex($ewkb) };
    ok $got, "$wkt: decode_hex answers" or diag $@ or next;
    is $got->{type},  $type, "$wkt: the type is named";
    is $got->{srid},  4326,  "$wkt: SRID";
    is $got->{has_z}, $z,    "$wkt: Z flag";
    is $got->{has_m}, $m,    "$wkt: M flag";
    is $got->{coords}, undef, "$wkt: nothing decoded";
  }
};

# The members of a MULTI* or a collection have a header of their own, and
# PostGIS (ST_GeomFromEWKB) reads its byte order: a big-endian member in a
# little-endian value, and the other way round, is the same geometry. The
# decoder used the byte order of the outer header for everything.
subtest 'a member has a byte order of its own' => sub {
  my $be_head = sub { pack 'C N', 0, $_[0] };
  my $be_pt   = sub { pack 'd>*', @_ };
  my $got = $dec->($hex_of->(
    $head->(4), pack('V', 2),
    $be_head->(1), $be_pt->(1, 2),
    $head->(1),    $point->(3, 4),
  ));
  is_deeply $got->{coords}, [[1,2],[3,4]], 'big-endian member in a little-endian multipoint';

  $got = $dec->($hex_of->(
    $be_head->(4), pack('N', 2),
    $head->(1),    $point->(1, 2),
    $be_head->(1), $be_pt->(3, 4),
  ));
  is_deeply $got->{coords}, [[1,2],[3,4]], 'little-endian member in a big-endian multipoint';

  # The counts of a member are read in the member's order as well.
  $got = $dec->($hex_of->(
    $head->(5), pack('V', 1),
    $be_head->(2), pack('N', 2), $be_pt->(0, 0), $be_pt->(1, 1),
  ));
  is_deeply $got->{coords}, [[[0,0],[1,1]]], 'big-endian line in a little-endian multilinestring';

  $got = $dec->($hex_of->(
    $head->(7), pack('V', 2),
    $be_head->(1), $be_pt->(1, 2),
    $be_head->(2), pack('N', 2), $be_pt->(0, 0), $be_pt->(1, 1),
  ));
  is_deeply $got->{coords}, [
    { type => 'point', coords => [1,2], is_empty => 0 },
    { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 },
  ], 'big-endian members of a little-endian collection';

  # A byte order that is none, in a member, is refused like one in the header.
  my $bad = eval { $d->decode_hex($hex_of->(
    $head->(4), pack('V', 1), pack('C V', 2, 1), $point->(1, 2),
  )) };
  is $bad, undef, 'a member byte order that is none: no answer';
  like $@, qr/decode_hex: invalid byte_order/, '... naming it';
};

# PostGIS never writes an SRID into a member. ST_GeomFromEWKB accepts one
# and drops it (the SRID of the whole is that of the outer header, 3857
# below, not the 4326 of the member). The decoder reads the SRID word and
# drops it as well, where it used to read it as the first ordinate.
subtest 'a member with an SRID flag' => sub {
  my $got = $dec->($hex_of->(
    $head->(4 | $SRID), pack('V', 3857), pack('V', 1),
    $head->(1 | $SRID), pack('V', 4326), $point->(1, 2),
  ));
  is $got->{srid}, 3857, 'the SRID is that of the outer header';
  is_deeply $got->{coords}, [[1,2]], 'the member SRID is dropped, not read as an ordinate';

  $got = $dec->($hex_of->(
    $head->(7), pack('V', 2),
    $head->(2 | $SRID), pack('V', 4326), $line->([0,0],[1,1]),
    $head->(1), $point->(5, 6),
  ));
  is $got->{srid}, undef, 'no outer SRID';
  is_deeply $got->{coords}, [
    { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 },
    { type => 'point', coords => [5,6], is_empty => 0 },
  ], 'in a collection, too';
};

# A member must have the dimensions of the whole: ST_GeomFromEWKB says
# "Dimensions mismatch in lwcollection", for MULTI* and collections, in
# every combination of Z and M tried. The decoder read a member with the
# flags of the outer header, so a member of other dimensions was read at
# the wrong width.
subtest 'a member of other dimensions than the whole is refused' => sub {
  my $Z = 0x80000000; my $M = 0x40000000;
  my %bad = (
    'MULTIPOINT Z, 2D member' => [ 4 | $Z,      1,      [1, 2] ],
    'MULTIPOINT, Z member'    => [ 4,           1 | $Z, [1, 2, 3] ],
    'COLLECTION, M member'    => [ 7,           1 | $M, [1, 2, 3] ],
    'COLLECTION Z, 2D member' => [ 7 | $Z,      1,      [1, 2] ],
    'COLLECTION ZM, Z member' => [ 7 | $Z | $M, 1 | $Z, [1, 2, 3] ],
  );
  for my $name (sort keys %bad) {
    my ($outer, $inner, $pt) = @{ $bad{$name} };
    my $got = eval { $d->decode_hex($hex_of->(
      $head->($outer), pack('V', 1), $head->($inner), $point->(@$pt),
    )) };
    is $got, undef, "$name: no answer" or diag explain $got;
    like $@, qr/decode_hex: member .*dimensions/, "$name: the error names the dimensions"
      or diag $@;
  }
  my $ok = $dec->($hex_of->(
    $head->(4 | $Z), pack('V', 1), $head->(1 | $Z), $point->(1, 2, 3),
  ));
  is_deeply $ok->{coords}, [[1,2,3]], 'MULTIPOINT Z with a Z member: read';
};

# ISO WKB writes the dimension into the type code (1001 = POINT Z, 2001 =
# POINT M, 3001 = POINT ZM). PostGIS reads those codes but never sends
# them, and this decoder does not read them: the type word is masked with
# 0xFFFF, so 1001 is a type id without a name. It is decoded like any such
# id -- header only, no type, no coordinates -- and does not throw.
# (Maintainer decision, karr k25.)
subtest 'ISO WKB type codes are not read' => sub {
  for my $iso (1001, 2001, 3001, 1002, 1007) {
    my $got = eval { $d->decode_hex($hex_of->($head->($iso), $point->(1, 2, 3))) };
    ok $got, "$iso: decode_hex answers" or diag $@ or next;
    is $got->{type},   undef, "$iso: no type";
    is $got->{coords}, undef, "$iso: no coordinates";
    is $got->{has_z},  0,     "$iso: no Z flag";
  }
};

# Emptiness (karr k19) and the parts of a collection (karr k24). The hex
# strings are what a PostGIS 3.6 server sends for ST_GeomFromText(<wkt>,
# 4326); t/36-empty-collection-live.t holds them against the server it
# runs on. PostGIS writes POINT EMPTY as a point of NaN ordinates, every
# other empty geometry as a count of 0. The decoder reports is_empty as
# ST_IsEmpty does: a geometry is empty if it has no parts or only empty
# ones (MULTIPOINT(EMPTY) is empty). An empty point has coords [], not
# [NaN, NaN].
my $NaN = 'NaN' + 0;
my $pt = sub { { type => 'point', coords => $_[0], is_empty => $_[1] // 0 } };
my @empty_cases = (
  [ 'POINT EMPTY', '0101000020e6100000000000000000f87f000000000000f87f',
    'point', [], 1, 0, 0 ],
  [ 'POINT Z EMPTY', '01010000a0e6100000000000000000f87f000000000000f87f000000000000f87f',
    'point', [], 1, 1, 0 ],
  [ 'POINT M EMPTY', '0101000060e6100000000000000000f87f000000000000f87f000000000000f87f',
    'point', [], 1, 0, 1 ],
  [ 'LINESTRING EMPTY', '0102000020e610000000000000', 'linestring', [], 1, 0, 0 ],
  [ 'LINESTRING ZM EMPTY', '01020000e0e610000000000000', 'linestring', [], 1, 1, 1 ],
  [ 'POLYGON EMPTY', '0103000020e610000000000000', 'polygon', [], 1, 0, 0 ],
  [ 'MULTIPOINT EMPTY', '0104000020e610000000000000', 'multipoint', [], 1, 0, 0 ],
  [ 'MULTIPOINT Z EMPTY', '01040000a0e610000000000000', 'multipoint', [], 1, 1, 0 ],
  [ 'GEOMETRYCOLLECTION EMPTY', '0107000020e610000000000000',
    'geometrycollection', [], 1, 0, 0 ],
  [ 'GEOMETRYCOLLECTION Z EMPTY', '01070000a0e610000000000000',
    'geometrycollection', [], 1, 1, 0 ],
  # Empty parts: the part stays in its place as an empty list.
  [ 'MULTIPOINT(EMPTY,(1 2))',
    '0104000020e6100000020000000101000000000000000000f87f000000000000f87f0101000000000000000000f03f0000000000000040',
    'multipoint', [ [], [1,2] ], 0, 0, 0 ],
  [ 'MULTIPOINT((1 2),EMPTY)',
    '0104000020e6100000020000000101000000000000000000f03f00000000000000400101000000000000000000f87f000000000000f87f',
    'multipoint', [ [1,2], [] ], 0, 0, 0 ],
  [ 'MULTIPOLYGON(EMPTY,((0 0,1 0,1 1,0 0)))',
    '0106000020e6100000020000000103000000000000000103000000010000000400000000000000000000000000000000000000000000000000f03f0000000000000000000000000000f03f000000000000f03f00000000000000000000000000000000',
    'multipolygon', [ [], [[[0,0],[1,0],[1,1],[0,0]]] ], 0, 0, 0 ],
  # A geometry of nothing but empty parts is empty (ST_IsEmpty says so).
  [ 'MULTIPOINT(EMPTY)',
    '0104000020e6100000' . unpack('H*', pack('V C V d< d<', 1, 1, 1, $NaN, $NaN)),
    'multipoint', [ [] ], 1, 0, 0 ],
  [ 'GEOMETRYCOLLECTION(POLYGON EMPTY)', '0107000020e610000001000000010300000000000000',
    'geometrycollection', [ { type => 'polygon', coords => [], is_empty => 1 } ], 1, 0, 0 ],
  [ 'GEOMETRYCOLLECTION(MULTIPOINT EMPTY)', '0107000020e610000001000000010400000000000000',
    'geometrycollection', [ { type => 'multipoint', coords => [], is_empty => 1 } ], 1, 0, 0 ],
  [ 'GEOMETRYCOLLECTION Z (POINT Z EMPTY)',
    '01070000a0e6100000010000000101000080000000000000f87f000000000000f87f000000000000f87f',
    'geometrycollection', [ $pt->([], 1) ], 1, 1, 0 ],
  [ 'GEOMETRYCOLLECTION(POINT EMPTY,LINESTRING(0 0,1 1))',
    '0107000020e6100000020000000101000000000000000000f87f000000000000f87f01020000000200000000000000000000000000000000000000000000000000f03f000000000000f03f',
    'geometrycollection',
    [ $pt->([], 1), { type => 'linestring', coords => [[0,0],[1,1]], is_empty => 0 } ], 0, 0, 0 ],
  # Parts of every kind, and a collection in a collection.
  [ 'GEOMETRYCOLLECTION(MULTIPOINT((1 2),(3 4)),POLYGON((0 0,1 0,1 1,0 0)))',
    '0107000020e6100000020000000104000000020000000101000000000000000000f03f00000000000000400101000000000000000000084000000000000010400103000000010000000400000000000000000000000000000000000000000000000000f03f0000000000000000000000000000f03f000000000000f03f00000000000000000000000000000000',
    'geometrycollection',
    [ { type => 'multipoint', coords => [[1,2],[3,4]], is_empty => 0 },
      { type => 'polygon', coords => [[[0,0],[1,0],[1,1],[0,0]]], is_empty => 0 } ], 0, 0, 0 ],
  [ 'GEOMETRYCOLLECTION(GEOMETRYCOLLECTION(POINT(1 2)),POINT(3 4))',
    '0107000020e610000002000000' . '0107000000' . '01000000' . '0101000000' . unpack('H*', pack('d< d<', 1, 2))
      . '0101000000' . unpack('H*', pack('d< d<', 3, 4)),
    'geometrycollection',
    [ { type => 'geometrycollection', coords => [ $pt->([1,2]) ], is_empty => 0 }, $pt->([3,4]) ], 0, 0, 0 ],
  [ 'GEOMETRYCOLLECTION M (POINT M (1 2 3))',
    '0107000060e6100000010000000101000040000000000000f03f00000000000000400000000000000840',
    'geometrycollection', [ $pt->([1,2,3]) ], 0, 0, 1 ],
);
for my $c (@empty_cases) {
  my ($wkt, $hex, $type, $coords, $empty, $z, $m) = @$c;
  subtest "empty and parts: $wkt" => sub {
    my $got = eval { $d->decode_hex($hex) };
    ok $got, 'decodes' or diag $@ or return;
    is $got->{type},     $type,   'type';
    is $got->{is_empty}, $empty,  'is_empty';
    is $got->{has_z},    $z,      'Z flag';
    is $got->{has_m},    $m,      'M flag';
    is_deeply $got->{coords}, $coords, 'coords' or diag explain $got->{coords};
  };
}

# A value that is not decoded says nothing about emptiness: is_empty is
# undef, not 0.
subtest 'a value that is not decoded has no is_empty' => sub {
  my $got = $d->decode_hex(
    '0108000020E61000000300000000000000000000000000000000000000000000000000F03F000000000000F03F00000000000000400000000000000000'
  );
  ok exists $got->{is_empty}, 'is_empty is in the answer ...';
  is $got->{is_empty}, undef, '... and is undef';
};

# A point with one NaN ordinate is a point, not an empty one.
subtest 'a point with a single NaN ordinate is not empty' => sub {
  my $got = $dec->($hex_of->($head->(1), $point->($NaN, 2)));
  is $got->{is_empty}, 0, 'not empty';
  is scalar @{ $got->{coords} }, 2, 'coords keep both ordinates';
};

# A NaN pair inside a line is a coordinate like any other, not an empty
# point: only a POINT (or a member of a MULTIPOINT or collection) is.
subtest 'NaN in a line is not an empty point' => sub {
  my $got = $dec->($hex_of->($head->(2), $line->([$NaN, $NaN], [1, 1])));
  is $got->{is_empty}, 0, 'not empty';
  is scalar @{ $got->{coords} }, 2, 'both points kept';
};

# Collections nest at most 32 levels deep, the outermost being level 1;
# deeper input is refused like any other that is no EWKB.
subtest 'nesting of collections is limited to 32 levels' => sub {
  my $nested = sub {
    my $depth = shift;
    my $hex = '';
    $hex .= unpack('H*', pack('C V V', 1, 7, 1)) for 1 .. $depth - 1;
    $hex .= unpack('H*', pack('C V V', 1, 7, 0));
    return $hex;
  };

  my $got = eval { $d->decode_hex($nested->(32)) };
  ok $got, 'depth 32 is decoded' or diag $@;
  is $got->{type}, 'geometrycollection', '... as a collection';

  $got = eval { $d->decode_hex($nested->(33)) };
  is $got, undef, 'depth 33: no answer';
  like $@, qr/decode_hex: nesting too deep/, '... naming the limit';
  unlike $@, qr/[0-9a-f]{10}/, '... without the input in the message';

  my $started = time;
  eval { $d->decode_hex($nested->(100_000)) };
  like $@, qr/nesting too deep/, 'depth 100000 is refused';
  cmp_ok time - $started, '<', 2, '... fast';

  require DBIO::PostgreSQL::PostGIS::Geometry;
  my $g = DBIO::PostgreSQL::PostGIS::Geometry->from_ewkb_hex($nested->(33));
  isa_ok $g, 'DBIO::PostgreSQL::PostGIS::Geometry', 'from_ewkb_hex of depth 33';
  is $g->ewkb_hex, $nested->(33), '... keeps the hex';
  is $g->geometry_type, 'GEOMETRYCOLLECTION', '... and the type of its header';
  is $g->coordinates, undef, '... without coordinates';
};

done_testing;
