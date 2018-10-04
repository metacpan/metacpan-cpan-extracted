#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Date::Baha::i';

my %d = to_bahai(
    year  => 2018,
    month => 10,
    day   => 2,
);

my $s = as_string( \%d,
    alpha   => 0,
    numeric => 0,
    size    => 0,
);
my $expected = "week day Fidal, day Rahmat of month Mashiyyat, year one seventy-five, Dal of the vahid Hubb of the first kull-i-shay";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 0,
    numeric => 0,
    size    => 1,
);
$expected = "week day Fidal, day Rahmat of month Mashiyyat, year one seventy-five, Dal of the vahid Hubb of the first kull-i-shay";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 0,
    numeric => 1,
    size    => 0,
);
$expected = "175/11/6";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 0,
    numeric => 1,
    size    => 1,
);
$expected = "fourth day of the week, sixth day of the eleventh month, year 175, fourth year of the tenth vahid of the first kull-i-shay";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 1,
    numeric => 0,
    size    => 0,
);
$expected = "Fidal, Rahmat of Mashiyyat, Dal of Hubb";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 1,
    numeric => 0,
    size    => 1,
);
$expected = "week day Fidal, day Rahmat of month Mashiyyat, year one seventy-five, Dal of the vahid Hubb of the first kull-i-shay";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 1,
    numeric => 1,
    size    => 0,
);
$expected = "Fidal (4), Rahmat (6) of Mashiyyat (11), year 175, Dal (4) of Hubb (10)";
is $s, $expected, 'as_string';

$s = as_string( \%d,
    alpha   => 1,
    numeric => 1,
    size    => 1,
);
$expected = "fourth week day Fidal, sixth day Rahmat of the eleventh month Mashiyyat, year one seventy-five (175), fourth year Dal of the tenth vahid Hubb of the first kull-i-shay";
is $s, $expected, 'as_string';

done_testing();
