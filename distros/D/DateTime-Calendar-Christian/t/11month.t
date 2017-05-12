use 5.008004;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();
use DateTime::Calendar::Christian;

#########################

my ($d, $r);

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 2003, month => 6 );

is( $d->ymd, '2003-06-30', 'ordinary month');

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 1500, month => 2 );

is( $d->ymd, '1500-02-29', 'Julian leap month');

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 1582, month => 10 );

is( $d->ymd, '1582-10-31', 'month of calendar reform');

$r = DateTime::Calendar::Christian->new(
        year  => 1650, month => 3, day => 1 );

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 1650, month => 2, reform_date => $r );

is( $d->ymd, '1650-02-18', 'incomplete month');

$r = DateTime::Calendar::Christian->new(
        year  => 1650, month => 3, day => 5 );

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 1650, month => 2, reform_date => $r );

is( $d->datetime, '1650-02-22J00:00:00', 'less incomplete month');

$r = DateTime::Calendar::Christian->new(
        year  => 1600, month => 3, day => 1 );

$d = DateTime::Calendar::Christian->last_day_of_month(
        year  => 1600, month => 2, reform_date => $r );

is( $d->ymd, '1600-02-19', 'incomplete month 1600-02');

done_testing;

# ex: set textwidth=72 :
