use strict;
BEGIN { $^W = 1 }

use Test::More tests => 13;
use DateTime::Calendar::Pataphysical;

#########################

my $d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 120, month => 2 );
is( $d->ymd, '120-02-29', 'last_day day' );
ok( $d->is_imaginary, '29-02 is_imaginary' );

$d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 120, month => 11 );

is( $d->ymd, '120-11-29', 'last_day day (gras)' );
ok( ! $d->is_imaginary, '29-11 is not imaginary' );

# leap year
$d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 123, month => 6 );

is( $d->ymd, '123-06-29', 'last_day day (leap day)' );
ok( ! $d->is_imaginary, 'leap day is not imaginary' );
ok( $d->is_leap_year, 'leap day in leap year' );

# no leap year
$d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 27, month => 6 );

is( $d->ymd, '027-06-29', 'last_day day (no leap day, 1900)' );
ok( $d->is_imaginary, '... is imaginary' );
ok( ! $d->is_leap_year, 'no leap year' );

# leap year
$d = DateTime::Calendar::Pataphysical->last_day_of_month(
            year => 127, month => 6 );

is( $d->ymd, '127-06-29', 'last_day day (leap day, 2000)' );
ok( ! $d->is_imaginary, 'leap day is not imaginary' );
ok( $d->is_leap_year, 'leap day in leap year' );
