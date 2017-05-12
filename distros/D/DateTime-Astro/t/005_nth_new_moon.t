use strict;
use Test::More;

use_ok "DateTime::Astro",
    "nth_new_moon",
    "lunar_longitude_from_moment",
    "solar_longitude_from_moment",
    "dt_from_moment",
    "lunar_phase"
;

my $DELTA_LONGITUDE = $ENV{ALLOW_NEW_MOON_DELTA_LONGITUDE} || 0.007;
my $DELTA_PHASE = $ENV{ALLOW_NEW_MOON_DELTA_PHASE} || 0.5;

my @data = (map { chomp; [ split /\s+/, $_ ] } <DATA>);

foreach my $data (@data) {
    my ($n, $y, $m, $d, $H, $M) = @$data;
    subtest "$n-th new moon ($y-$m-$d $H:$M)" => sub {
        my $moment = nth_new_moon($n);
        ok $moment > 0, "$n-th new moon ($moment)";
        my $lunar_longitude = lunar_longitude_from_moment($moment);
        my $solar_longitude = solar_longitude_from_moment($moment);

        note "solar longitude = $solar_longitude";
        note "lunar longitude = $lunar_longitude";

        my $delta = $lunar_longitude - $solar_longitude;
        ok $delta < $DELTA_LONGITUDE, "$n-th new moon [lunar = $lunar_longitude][solar = $solar_longitude][delta = $delta] (allowed delta = $DELTA_LONGITUDE)";
        my $dt = dt_from_moment( $moment );

        is $dt->year,  $y, "[year = " . $dt->year . "] ($y) $dt";
        is $dt->month, $m, "[month = " . $dt->month . "] ($m) $dt";
        is $dt->day,   $d, "[day = " . $dt->day . "] ($d) $dt";
        is $dt->hour,  $H, "[hour = " . $dt->hour . "] ($H) $dt";

        ok abs($dt->minute - $M) <= 1, "[minute = " . $dt->minute . "] ($M) $dt";

        my $lunar_phase = lunar_phase($dt);
        $delta = ($lunar_phase > 180) ? 360 - $lunar_phase : $lunar_phase;
        ok $delta < $DELTA_PHASE, "[phase = $lunar_phase][delta = $delta] (0)";
        done_testing;
    };
}
done_testing;

# NOTE changed 0th new moon values from hour = 13 -> 10, minute 44 -> 13
__DATA__
0        1  1 11 10 13
21014 1700  1 20  4 20
21015 1700  2 18 23 33
21016 1700  3 20 16 46
21017 1700  4 19  6 51
21018 1700  5 18 17 45
21019 1700  6 17  2 14
21020 1700  7 16  9 32
21021 1700  8 14 16 45
21022 1700  9 13  0 47
21023 1700 10 12 10 15
21024 1700 11 10 21 44
21025 1700 12 10 11 44
24712 1999  1 17 15 46
24713 1999  2 16  6 39
24714 1999  3 17 18 48
24715 1999  4 16  4 22
24716 1999  5 15 12  5
24717 1999  6 13 19  3
24718 1999  7 13  2 24
24719 1999  8 11 11  8
24720 1999  9  9 22  2
24721 1999 10  9 11 34
24722 1999 11  8  3 53
24723 1999 12  7 22 32
24724 2000  1  6 18 14
24725 2000  2  5 13  3
24726 2000  3  6  5 17
24727 2000  4  4 18 12
24728 2000  5  4  4 12
24729 2000  6  2 12 14
24730 2000  7  1 19 20
24731 2000  7 31  2 25
24732 2000  8 29 10 19
24733 2000  9 27 19 53
24734 2000 10 27  7 58
24735 2000 11 25 23 11
24736 2000 12 25 17 22
