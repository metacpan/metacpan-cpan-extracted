#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

use Date::Japanese::Era 'Builder';

# Sets the table up as JIS_X0301
Date::Japanese::Era::Table::Builder::build_table(
    ["\x{660E}\x{6CBB}", 'meiji',   1868,  9,  8],
    ["\x{5927}\x{6B63}", 'taishou', 1912,  7, 31],
    ["\x{662D}\x{548C}", 'shouwa',  1926, 12, 26],
    ["\x{5E73}\x{6210}", 'heisei',  1989,  1,  8],
    ["\x{4EE4}\x{548C}", 'reiwa',   2019,  5,  1],
);

my $era = Date::Japanese::Era->new(1912,7,30);

ok($era->name eq "\x{660E}\x{6CBB}", 'Meji\'s last day is Meji');

$era = Date::Japanese::Era->new(1912,7,31);

ok($era->name eq "\x{5927}\x{6B63}", 'Taisho\'s first day is Taisho');

$era = Date::Japanese::Era->new(3000,1,1);

ok($era->name eq "\x{4EE4}\x{548C}", 'Reiwa rules into the far future');

