use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

my ($greg, $d);

$greg = DateTime->new( year => 2003, month => 1, day => 1,
                       time_zone => 'floating' );
$d = DateTime::Calendar::Christian->from_object( object => $greg );

ok( $d->is_gregorian, '2003 is gregorian' );
is( $d->ymd, '2003-01-01', 'conversion succeeded' );

$greg = DateTime->new( year => 1515, month => 1, day => 20,
                       time_zone => 'floating' );
$d = DateTime::Calendar::Christian->from_object( object => $greg );

ok( $d->is_julian, '1515 is julian' );
is( $d->ymd, '1515-01-10', 'conversion succeeded' );

$greg = DateTime->new( year => 1582, month => 10, day => 14,
                       time_zone => 'floating' );
$d = DateTime::Calendar::Christian->from_object( object => $greg );

ok( $d->is_julian, '1582-10-14(greg) is julian' );
is( $d->ymd, '1582-10-04', 'conversion succeeded' );

$greg = DateTime->new( year => 1582, month => 10, day => 15,
                       time_zone => 'floating' );
$d = DateTime::Calendar::Christian->from_object( object => $greg );

ok( $d->is_gregorian, '1582-10-15 is gregorian' );
is( $d->ymd, '1582-10-15', 'conversion succeeded' );

done_testing;

# ex: set textwidth=72 :
