use strict;
BEGIN { $^W = 1 }

use Test::More tests => 5;
use DateTime::Calendar::Hijri;

my $dt = DateTime::Calendar::Hijri->new( year => 1424,
                                         month => 7,
                                         day => 10 );

isa_ok( $dt, 'DateTime::Calendar::Hijri' );

is( $dt->year, 1424, 'correct year' );
is( $dt->month, 7, 'correct month' );
is( $dt->day, 10, 'correct day' );

is( $dt->datetime, '1424-7-10 AH', 'correct datetime' );
