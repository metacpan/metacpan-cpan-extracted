#!perl -T

use Test::Simple tests => 6;
use Algorithm::Kuhn::Munkres qw( assign );

my @matrix = ([1,2,3,4],[2,4,6,8],[3,6,9,12],[4,8,12,16]);
my ($cost,$mapping) = assign(@matrix);
ok($cost == 30);

@matrix = ([1,2,3],[3,3,3],[3,3,2]);
($cost,$mapping) = assign(@matrix);
ok($cost == 9);

@matrix = ([7,4,3],[3,1,2],[3,0,0]);
($cost,$mapping) = assign(@matrix);
ok($cost == 9);

@matrix = ([-1,-2,-3],[-3,-3,-3],[-3,-3,-2]);
($cost,$mapping) = assign(@matrix);
ok($cost == -6);

@matrix = (
[62,75,80,93,95,97],
[75,80,82,85,71,97],
[80,75,81,98,90,97],
[78,82,84,80,50,98],
[90,85,85,80,85,99],
[65,75,80,75,68,96]
);
($cost,$mapping) = assign(@matrix);
ok($cost == 543);
ok(Algorithm::Kuhn::Munkres::_show_hash($mapping) eq "{0: 4, 1: 1, 2: 3, 3: 2, 4: 0, 5: 5}");
