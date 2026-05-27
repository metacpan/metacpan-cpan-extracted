use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# parse_wkt: structured outputs must match the nested-arrayref shape
# that the Geo column encoders accept (covered separately in
# t/extended_types.t -- when the shapes drift, both files must agree).

is_deeply(ClickHouse::Encoder->parse_wkt('POINT(1 2)'),
          [1, 2], 'POINT');

is_deeply(ClickHouse::Encoder->parse_wkt('POINT(-1.5 2.25)'),
          [-1.5, 2.25], 'POINT: floats + negatives');

is_deeply(ClickHouse::Encoder->parse_wkt('LINESTRING(0 0, 1 1, 2 0)'),
          [[0,0],[1,1],[2,0]], 'LINESTRING');

is_deeply(ClickHouse::Encoder->parse_wkt('POLYGON((0 0, 4 0, 4 4, 0 4, 0 0))'),
          [[[0,0],[4,0],[4,4],[0,4],[0,0]]],
          'POLYGON: single outer ring');

is_deeply(
    ClickHouse::Encoder->parse_wkt(
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(2 2, 3 2, 3 3, 2 3, 2 2))'),
    [ [[0,0],[10,0],[10,10],[0,10],[0,0]],
      [[2,2],[3,2],[3,3],[2,3],[2,2]] ],
    'POLYGON: outer ring + hole');

is_deeply(
    ClickHouse::Encoder->parse_wkt(
        'MULTILINESTRING((0 0, 1 1),(2 2, 3 3))'),
    [ [[0,0],[1,1]], [[2,2],[3,3]] ],
    'MULTILINESTRING: two parts');

is_deeply(
    ClickHouse::Encoder->parse_wkt(
        'MULTIPOLYGON(((0 0, 1 0, 1 1, 0 0)),((2 2, 3 2, 3 3, 2 2)))'),
    [ [ [[0,0],[1,0],[1,1],[0,0]] ],
      [ [[2,2],[3,2],[3,3],[2,2]] ] ],
    'MULTIPOLYGON: two polygons, one ring each');

# Round-trip via the encoder: a WKT polygon parsed and fed to the Geo
# column must produce the same bytes as the equivalent hand-built input.
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['p',  'Point'],
        ['ls', 'LineString'],
        ['mp', 'MultiPolygon'],
    ]);
    my $manual = $enc->encode([[
        [1.5, 2.5],
        [[0,0],[1,1],[2,0]],
        [[[[0,0],[1,0],[1,1],[0,0]]]],
    ]]);
    my $wkt = $enc->encode([[
        ClickHouse::Encoder->parse_wkt('POINT(1.5 2.5)'),
        ClickHouse::Encoder->parse_wkt('LINESTRING(0 0, 1 1, 2 0)'),
        ClickHouse::Encoder->parse_wkt(
            'MULTIPOLYGON(((0 0, 1 0, 1 1, 0 0)))'),
    ]]);
    is($wkt, $manual, 'WKT-fed encoder matches manual nested-arrayref');
}

# Whitespace and case insensitivity: WKT is generally case-insensitive
# in real producers (PostGIS emits uppercase, JTS lowercase).
is_deeply(ClickHouse::Encoder->parse_wkt('  point ( 1 2 ) '),
          [1, 2], 'POINT: case-insensitive + extra whitespace');

# Error paths: malformed input must croak loudly rather than silently
# producing a wrong-shape arrayref.
for my $bad (
    [ 'POINT(1)',          qr/POINT needs 2 coords/        ],
    [ 'POINT 1 2',         qr/POINT missing/               ],
    [ 'CIRCLE(1 1, 5)',    qr/unsupported geometry/        ],
    [ 'POLYGON()',         qr/no parts parsed/             ],
    [ '',                  qr/not a WKT geometry/          ],
    [ undef,               qr/input required/              ],
    [ 'MULTIPOLYGON()',    qr/no polygons parsed/          ],
    [ 'LINESTRING(1 2 3)', qr/point needs 2 coords/        ],
    [ 'POINT(',            qr/POINT unmatched parens/      ],
) {
    my ($wkt, $re) = @$bad;
    local $@;
    eval { ClickHouse::Encoder->parse_wkt($wkt) };
    like($@, $re,
         "parse_wkt error: '" . (defined $wkt ? $wkt : '<undef>') . "' -> $re");
}

done_testing();
