
#!/usr/bin/env perl -w

use strict;
use warnings;

our $VERSION = 0.01;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Test::More;
use Test::Number::Delta within => 0.4;

BEGIN {
    use_ok( 'Astro::Montenbruck::Lunation', qw/:all/ );
}

subtest 'search_event' => sub {
    my @cases = (
        [ [1977, 2, 15], $NEW_MOON     , 2443192.65118, 120.96 ],
        [ [1965, 2,  1], $FIRST_QUARTER, 2438800.87026, 328.72 ],
        [ [1965, 2,  1], $FULL_MOON    , 2438807.52007, 66.39 ],
        [ [2044, 1,  1], $LAST_QUARTER , 2467636.49186, 218.47 ],
        [ [2019, 8, 21], $NEW_MOON     , 2458725.94287, 53.64 ],
        [ [2019, 8, 21], $FIRST_QUARTER, 2458732.63302, 151.31 ],
        [ [2019, 8, 21], $FULL_MOON    , 2458740.69049, 248.98 ],
        [ [2019, 8, 21], $LAST_QUARTER , 2458748.61252, 346.65 ],
    );

    for (@cases) {
        my ($date, $q, $exp_j, $exp_f) = @$_;
        my ($j, $f) = search_event($date, $q);
        delta_ok($j, $exp_j, sprintf('%s on %d-%d-%d', $q, @$date));
        delta_within($f, $exp_f, 0.2, sprintf('F on %d-%d-%d', @$date));
    }
    done_testing();
};

done_testing();
