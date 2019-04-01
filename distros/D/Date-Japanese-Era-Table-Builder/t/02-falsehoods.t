#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

use Date::Japanese::Era::Table::Builder;

ok( ! eval {
# Sets the table up as JIS_X0301, but out of order
build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5927}\x{6B63}", 'taishou', 1912,  7, 31],
    ["\x{5E73}\x{6210}", 'heisei',  1989,  1,  8],
    ["\x{662D}\x{548C}", 'shouwa',  1926, 12, 26],
    ["\x{4EE4}\x{548C}", 'reiwa',   2019,  5,  1],
);
1;
}, 'Eras out of order throw an error');

ok( ! eval {
# Sets the table up as JIS_X0301, but out with too short an era.
build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5927}\x{6B63}", 'taishou', 1912,  7, 31],
    ["\x{662D}\x{548C}", 'shouwa',  1926, 12, 26],
    ["\x{5E73}\x{6210}", 'heisei',  1926, 12, 26],
    ["\x{4EE4}\x{548C}", 'reiwa',   2019,  5,  1],
);
1;
}, 'Too short eras throw an error.');

ok( eval {
# Sets the table up as JIS_X0301, but out with a very short era.
build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5927}\x{6B63}", 'taishou', 1912,  7, 31],
    ["\x{662D}\x{548C}", 'shouwa',  1926, 12, 26],
    ["\x{5E73}\x{6210}", 'heisei',  1926, 12, 27],
    ["\x{4EE4}\x{548C}", 'reiwa',   2019,  5,  1],
);
1;
}, 'Single-day eras throw no error.');

ok( ! eval {
build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5E73}\x{6210}", 'heisei',  1926, 12],
);
1;
}, 'Malformed era entries throw an error.');
