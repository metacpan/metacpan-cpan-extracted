use strict;
use Test::More;

use_ok "DateTime::Astro", "nth_new_moon", "lunar_longitude_from_moment", "solar_longitude_from_moment", "dt_from_moment";

my $DELTA_LONGITUDE = $ENV{ALLOW_NEW_MOON_DELTA_LONGITUDE} || 0.018;

for my $n (20000..24736) {
    subtest "$n-th new_moon" => sub {
        my $moment = nth_new_moon($n);
        ok $moment > 0, "$n-th new moon ($moment)";
        my $lunar_longitude = lunar_longitude_from_moment($moment);
        my $solar_longitude = solar_longitude_from_moment($moment);

        my $delta = $lunar_longitude - $solar_longitude;
        if (! ok $delta < $DELTA_LONGITUDE, "$n-th new moon [lunar = $lunar_longitude][solar = $solar_longitude][delta = $delta] (allowed delta = $DELTA_LONGITUDE)") {
            diag( dt_from_moment( $moment ) );
        }
        done_testing;
    };
}
done_testing;
