use strict;
BEGIN { $^W = 1 }

use Test::More tests => 14;
use DateTime::Calendar::Pataphysical;

#########################

my $dt = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 2, day => 1);

$dt->add( days => 10 );
is( $dt->ymd, '130-02-11', 'adding days within month' );

$dt->add( days => 20 );
is( $dt->ymd, '130-03-02', 'adding days across month boundary' );

$dt->add( days => 27 );
is( $dt->ymd, '130-03-29', 'adding days to hunyadi' );

$dt->subtract( days => 40 );
is( $dt->ymd, '130-02-18', 'subtracting days' );

$dt->add( months => 4 );
is( $dt->ymd, '130-06-18', 'adding months' );

$dt->add( months => 12 );
is( $dt->ymd, '131-05-18', 'adding months across year boundary' );

$dt->subtract( months => 20 );
is( $dt->ymd, '129-11-18', 'subtracting months' );

my $dt1 = DateTime::Calendar::Pataphysical->new(
            year => 129, month => 11, day => 19);
my $dt2 = DateTime::Calendar::Pataphysical->new(
            year => 130, month => 2, day => 1);

my $dur = $dt1 - $dt2;
isa_ok( $dur, 'DateTime::Duration' );

my %deltas = $dur->deltas;
is( $deltas{days}, -98, 'subtracting datetimes' );

$dt = $dt2 + $dur;
is( $dt->ymd, $dt1->ymd, 'adding duration' );

ok( $dt2 > $dt1, 'comparing years' );

$dt2 = DateTime::Calendar::Pataphysical->new(
            year => 129, month => 2, day => 1);
ok( $dt2 < $dt1, 'comparing months' );

$dt2 = DateTime::Calendar::Pataphysical->new(
            year => 129, month => 11, day => 5);
ok( $dt2 < $dt1, 'comparing days' );

$dt2 = $dt;
ok( $dt2 == $dt1, 'identical days' );
