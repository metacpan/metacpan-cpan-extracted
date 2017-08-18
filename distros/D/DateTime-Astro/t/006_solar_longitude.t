use strict;
use Test::More;
use t::DateTime::Astro::Test qw(datetime);
use_ok "DateTime::Astro", "solar_longitude", "solar_longitude_after", "solar_longitude_before";

my $DELTA_LONGITUDE = $ENV{ALLOW_SOLAR_LONGITUDE_DELTA} || 0.006;

# http://aa.usno.navy.mil/data/docs/EarthSeasons.php
my @data = (
    # XXX these data are now gone from above website
    [   0, 1992,  3, 20,  8, 48 ],
    [  90, 1992,  6, 21,  3, 14 ],
    [ 270, 1992, 12, 21, 14, 43 ],
    [  90, 1993,  6, 21,  9, 00 ],
    [ 270, 1993, 12, 21, 20, 26 ],
    [  90, 1994,  6, 21, 14, 48 ],
    [  90, 1999,  6, 21, 19, 49 ],

    # XXX these are there as of 6/12/2010
    [   0, 2000,  3, 20,  7, 35 ],
    [  90, 2000,  6, 21,  1, 48 ],
    [ 180, 2000,  9, 22, 17, 28 ],
    [ 270, 2000, 12, 21, 13, 37 ],
    [   0, 2001,  3, 20, 13, 31 ],
    [  90, 2001,  6, 21,  7, 38 ],
    [ 180, 2001,  9, 22, 23,  4 ],
    [ 270, 2001, 12, 21, 19, 21 ],
    [   0, 2002,  3, 20, 19, 16 ],
    [  90, 2002,  6, 21, 13, 24 ],
    [ 180, 2002,  9, 23,  4, 55 ],
    [ 270, 2002, 12, 22,  1, 14 ],
    [   0, 2003,  3, 21,  1,  0 ],
    [  90, 2003,  6, 21, 19, 10 ],
    [ 180, 2003,  9, 23, 10, 47 ],
    [   0, 2004,  3, 20,  6, 49 ],
    [  90, 2004,  6, 21,  0, 57 ],
    [ 180, 2004,  9, 22, 16, 30 ],
    [   0, 2005,  3, 20, 12, 33 ],
    [  90, 2005,  6, 21,  6, 46 ],
    [ 180, 2005,  9, 22, 22, 23 ],
    [   0, 2006,  3, 20, 18, 26 ],
    [  90, 2006,  6, 21, 12, 26 ],
    [ 180, 2006,  9, 23,  4,  3 ],
    [   0, 2007,  3, 21,  0,  7 ],
    [  90, 2007,  6, 21, 18,  6 ],
    [ 180, 2007,  9, 23,  9, 51 ],
    [   0, 2008,  3, 20,  5, 48 ],
    [  90, 2008,  6, 20, 23, 59 ],
    [ 180, 2008,  9, 22, 15, 44 ],
    [   0, 2009,  3, 20, 11, 44 ],
    [  90, 2009,  6, 21,  5, 46 ],
    [ 180, 2009,  9, 22, 21, 19 ],
    [ 270, 2003, 12, 22,  7,  4 ],
    [ 270, 2004, 12, 21, 12, 42 ],
    [ 270, 2005, 12, 21, 18, 35 ],
    [ 270, 2006, 12, 22,  0, 22 ],
    [ 270, 2007, 12, 22,  6,  8 ],
    [ 270, 2008, 12, 21, 12,  4 ],
    [ 270, 2009, 12, 21, 17, 47 ],
);

foreach my $data (@data) {
    my ($expected, $y, $m, $d, $H, $M) = @$data;

    my $dt = datetime($y, $m, $d, $H, $M);
    my $longitude = solar_longitude($dt);
    my $delta = abs($longitude - $expected);
    ok $delta < $DELTA_LONGITUDE,
        "[longitude = $longitude][expected = $expected][delta = $delta][dt = $dt ]";

    my $x = $dt->clone;
    $x->add( days => 10 );

    my $before = solar_longitude_before( $x, $expected );
    $delta = abs ($before->epoch - $dt->epoch);
    ok $delta < 540, # XXX TODO FIX
        "[before = $before][expected = $dt][delta = $delta]";

    $x = $dt->clone;
    $x->subtract( days => 10 );
    my $after = solar_longitude_after( $x, $expected );
    $delta = abs ($after->epoch - $dt->epoch);
    ok $delta < 540,
        "[after = $after][expected = $dt][delta = $delta]";
}

done_testing;
