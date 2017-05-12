# Test object creation, when ISO date is passed in

use Test::More qw(no_plan);

BEGIN {
    use_ok ('Date::ISO');
}

my $iso;

# Date formats:

# Creating with 1997-02-05 format

$iso = {};
$iso = Date::ISO->new( iso => '1971-10-25', offset=>0 );
is( $iso->offset, 0, "Offset 0");
is( $iso->year, 1971, 'year()' );
is( $iso->month, 10, 'month()' );
is( $iso->day, 25, 'day()' );

is( $iso->iso_year, 1971, 'iso_year()' );
is( $iso->iso_week, 43, 'iso_week()' );
is( $iso->iso_week_day, 1, 'iso_week_day()' );

# Creating with 19711025 format

$iso = {};
$iso = Date::ISO->new( iso => '19711025', offset=>0);
is( $iso->offset, 0, "Offset zero");
is( $iso->year, 1971, 'year()' );
is( $iso->month, '10', 'month()' );
is( $iso->day, '25', 'day()' );

is( $iso->iso_year, 1971, 'iso_year' );
is( $iso->iso_week, 43, 'iso_week' );
is( $iso->iso_week_day, 1, 'iso_week_day' );

# Creating with 197110 format

$iso = {};
$iso = Date::ISO->new( iso => '197110', offset => 0 );
is( $iso->year, 1971, 'year()');
is( $iso->month, 10, 'month()' );
is( $iso->day, 1, 'day()' ); # Day defaults to first of the month

is( $iso->iso_year, 1971, 'iso_year()' );
is( $iso->iso_week, 39, 'iso_week()' );
is( $iso->iso_week_day, 5, 'iso_week_day()' );

# Creating with '1971-W43' format

$iso={};
$iso = Date::ISO->new( iso => '1971-W43', offset => 0 );
is( $iso->year, 1971, 'year()');
is( $iso->month, 10, 'month()' );
is( $iso->day, 25, 'day()' );

is( $iso->iso_year, 1971, 'iso_year()' );
is( $iso->iso_week, 43, 'iso_week()' );
is( $iso->iso_week_day, 1, 'iso_week_day()' );

# Creating with '1971W43' format

$iso={};
$iso = Date::ISO->new( iso => '1971W43', offset => 0 );
is( $iso->year,1971, 'year()' );
is( $iso->month,10, 'month()' );
is( $iso->day,25, 'day()' );

is( $iso->iso_year,1971, 'iso_year()' );
is( $iso->iso_week,43, 'iso_week()' );
is( $iso->iso_week_day,1, 'iso_week_day()' );
# Creating with '1971-W43-1' format

$iso={};
$iso = Date::ISO->new( iso => '1971-W43-1', offset => 0 );
is( $iso->year,1971, 'year()' );
is( $iso->month,10, 'month()' );
is( $iso->day,25, 'day()' );

is( $iso->iso_year,1971, 'iso_year()' );
is( $iso->iso_week,43, 'iso_week()' );
is( $iso->iso_week_day,1, 'iso_week_day()' );

# Creating with '1971W431' format

$iso={};
$iso = Date::ISO->new( iso => '1971W431', offset => 0 );
is( $iso->year,1971, 'year()' );
is( $iso->month,10, 'month()' );
is( $iso->day,25, 'day()' );

is( $iso->iso_year,1971, 'iso_year()' );
is( $iso->iso_week,43, 'iso_week()' );
is( $iso->iso_week_day,1, 'iso_week_day()' );

# Creating with '1971-293' format

$iso={};
$iso = Date::ISO->new( iso => '1971-431', offset => 0 );
is( $iso->year,1971, 'year()' );
is( $iso->month,10, 'month()' );
is( $iso->day,25, 'day()' );

is( $iso->iso_year,1971, 'iso_year()' );
is( $iso->iso_week,43, 'iso_week()' );
is( $iso->iso_week_day,1, 'iso_week_day()' );

# Creating with '1971293' format

$iso={};
$iso = Date::ISO->new( iso => '1971431', offset => 0 );
is( $iso->year,1971, 'year()' );
is( $iso->month,10, 'month()' );
is( $iso->day,25, 'day()' );

is( $iso->iso_year,1971, 'iso_year()' );
is( $iso->iso_week,43, 'iso_week()' );
is( $iso->iso_week_day,1, 'iso_week_day()' );

