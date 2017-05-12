#!perl

use strict;
use Test::More (tests => 41);
BEGIN
{
    use_ok("DateTime::Util::Astro::Moon", qw(nth_new_moon lunar_longitude));
    use_ok("DateTime::Util::Astro::Sun",  qw(solar_longitude));
}

# Below table from http://aa.usno.navy.mil/data/docs/MoonPhase.html
# for year 2000

my @data = (     # new moon
    #     n    YYYY  MM  DD  HH  MM 
    [ 24724, [ 2000,  1,  6, 18, 14 ] ],
    [ 24725, [ 2000,  2,  5, 13,  3 ] ],
    [ 24726, [ 2000,  3,  6,  5, 17 ] ],
    [ 24727, [ 2000,  4,  4, 18, 12 ] ],
    [ 24728, [ 2000,  5,  4,  4, 12 ] ],
    [ 24729, [ 2000,  6,  2, 12, 14 ] ],
    [ 24730, [ 2000,  7,  1, 19, 20 ] ],
    [ 24731, [ 2000,  7, 31,  2, 25 ] ],
    [ 24732, [ 2000,  8, 29, 10, 19 ] ],
    [ 24733, [ 2000,  9, 27, 19, 53 ] ],
    [ 24734, [ 2000, 10, 27,  7, 58 ] ],
    [ 24735, [ 2000, 11, 25, 23, 11 ] ],
    [ 24736, [ 2000, 12, 25, 17, 22 ] ],
);

# Allow up to this amount of time difference from the navy data
#
#   ALLOW_NEW_MOON_DELTA_SECONDS
#   ALLOW_NEW_MOON_DELTA_LONGITUDE
#
my $DELTA_SECONDS   = $ENV{ALLOW_NEW_MOON_DELTA_SECONDS}   || 600;
my $DELTA_LONGITUDE = $ENV{ALLOW_NEW_MOON_DELTA_LONGITUDE} || 1;

foreach my $data (@data) {
    my($n, $dt_args) = @$data;
    my $dt  = nth_new_moon($n);
    my $ref = DateTime->new(
        year => $dt_args->[0],
        month => $dt_args->[1],
        day   => $dt_args->[2],
        hour  => $dt_args->[3],
        minute => $dt_args->[4],
        time_zone => 'UTC', 
    );

    my $delta = abs($dt->epoch - $ref->epoch);
    ok($delta < $DELTA_SECONDS, "Delta for n = $n. Delta = $delta, Allowed = $DELTA_SECONDS. \$dt = $dt, \$ref = $ref");

    my $sl = solar_longitude($dt);
    my $ll = lunar_longitude($dt);
    $delta = abs($sl - $ll);

    ok($delta < $DELTA_LONGITUDE, "Longitude delta for n = $n. Delta = $DELTA_LONGITUDE");

    SKIP: {
        # check cache
        my $cache  = DateTime::Util::Astro::Moon->cache;
        if (! $cache) {
            skip "no cache available", 1;
        } else {
            my $cached = $cache->get($n);
            ok($cached == $dt, "Cached result match");
        }
    }
}
