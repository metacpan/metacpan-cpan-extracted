
use strict;
use Test;

my @tests = (
    [      25 => '25s'           ],
    [      85 => '1m25s'         ],
    [     300 => '5m'            ],
    [    6000 => '1h40m'         ],
    [    7654 => '2h7m34s'       ],
    [   10000 => '2h46m40s'      ],
    [ 7654321 => '12w4d14h12m1s' ],
);

plan tests => 1+@tests;

eval { use Date::Lima qw/beek_date weeklargest_conversions/ }; ok( $@, '' );
weeklargest_conversions();

for my $i (@tests) {
    ok("$i->[0] -> " . beek_date($i->[0]), "$i->[0] -> $i->[1]");
}
