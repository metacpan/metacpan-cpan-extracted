use strict;
BEGIN { $^W = 1 }

use Test::More tests => 186;
use DateTime::Calendar::Pataphysical;

SKIP:{
    eval {require DateTime};
    skip 'DateTime not installed', 132 if $@;

#########################

for my $test ([ 1,  1,   1 => 1873,  9,  8 ],
              [28,  1,   1 => 1873, 10,  5 ],
              [ 1,  2,   1 => 1873, 10,  6 ],
              [28,  2,   1 => 1873, 11,  2 ],
              [ 1,  4,   1 => 1873, 12,  1 ],
              [28,  6,   1 => 1874,  2, 22 ],
              [ 1,  7,   1 => 1874,  2, 23 ],
              [ 1,  9,   1 => 1874,  4, 20 ],
              [ 1, 11,   1 => 1874,  6, 15 ],
              [28, 11,   1 => 1874,  7, 12 ],
              [29, 11,   1 => 1874,  7, 13 ],
              [ 1, 12,   1 => 1874,  7, 14 ],
              [28, 13,   1 => 1874,  9,  7 ],
              [ 1,  1,   2 => 1874,  9,  8 ],
              [ 1,  7,   2 => 1875,  2, 23 ],
              [ 1,  1,   3 => 1875,  9,  8 ],
              [28,  6,   3 => 1876,  2, 22 ],
              [29,  6,   3 => 1876,  2, 23 ],
              [ 1,  7,   3 => 1876,  2, 24 ],
              [ 6,  7,   3 => 1876,  2, 29 ],
              [ 7,  7,   3 => 1876,  3,  1 ],
              [28, 13,   3 => 1876,  9,  7 ],
              [28,  6,  27 => 1900,  2, 22 ],
              [ 1,  7,  27 => 1900,  2, 23 ],
              [28,  6, 127 => 2000,  2, 22 ],
              [29,  6, 127 => 2000,  2, 23 ],
              [ 1,  7, 127 => 2000,  2, 24 ],
              [ 1,  7,1002 => 2875,  2, 23 ],
              [ 1,  1,1003 => 2875,  9,  8 ],
              [ 1,  7,2002 => 3875,  2, 23 ],
              [ 1,  1,2003 => 3875,  9,  8 ],
              [ 1,  1,-1   => 1872,  9,  8 ],
              [ 1,  7,-998 =>  876,  2, 24 ],
              [ 1,  1,-997 =>  876,  9,  8 ], ) {
    my ($dp, $mp, $yp, $yg, $mg, $dg) = @$test;

    my $date = DateTime::Calendar::Pataphysical->new(
                    year => $yp, month => $mp, day => $dp );
    my $date_g = DateTime->from_object( object => $date );

    isa_ok( $date_g, 'DateTime', 'converted date'. $date->datetime );
    is( $date_g->ymd, sprintf( '%04d-%02d-%02d', $yg, $mg, $dg ),
            '... correctly' );
    is( $date->utc_rd_as_seconds, $date_g->utc_rd_as_seconds,
        'utc_rd_as_seconds is equal' );

    my $date_p = DateTime::Calendar::Pataphysical->from_object(
                object => $date_g );
    isa_ok( $date_p, "DateTime::Calendar::Pataphysical", 'and back' );
    is( $date_p->ymd, sprintf( '%0.3d-%0.2d-%0.2d', $yp, $mp, $dp ),
        '... correctly' );
}

my $d = DateTime->new( year => 2000, month => 2, day => 24,
                       time_zone => 'Europe/Amsterdam' );
my $dp = DateTime::Calendar::Pataphysical->from_object( object => $d );

is( $dp->ymd, '127-07-01', 'convert from local time instead of utc' );

#my $d2 = DateTime->from_object( object => $dp );
#is( $d2->offset, +3600, 'conversion keeps timezone intact' );
#is( $d2->datetime, '2000-02-24T00:00:00', '... and the correct time' );
} # end SKIP

#                yyy  mm  dd
for my $test ( [   1,  1, 29 ],
               [   1,  2, 29 ],
               [   1,  6, 29 ],
               [   1, 10, 29 ],
               [   1, 13, 29 ],
               [   2,  6, 29 ],
               [  27,  6, 29 ], ) {
    my ($y, $m, $d) = @$test;
    my $date = DateTime::Calendar::Pataphysical->new(
                    year => $y, month => $m, day => $d );
    my @rd = $date->utc_rd_values;
    is( @rd, 0, "$y-$m-$d (imaginary)" );
    ok( !defined $date->utc_rd_as_seconds, 'utc_rd_as_seconds not defined' );
}

my $date = DateTime->new( year => 2003, month => 1, day => 1,
                          hour => 22, minute => 20,
                          time_zone => 'America/Chicago' );
$date = DateTime::Calendar::Pataphysical->from_object( object => $date );
$date = DateTime->from_object( object => $date );

is( $date->datetime, '2003-01-01T22:20:00', 'Keep time in conversion' );
