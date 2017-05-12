# Testing object creation passing in an epoch time

use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Date::ISO' );
    use_ok( 'Time::Local' );
}

my $iso;

my $date = timegm(0,0,0,25,9,1971);
$iso = Date::ISO->new( epoch => $date, offset => 0 );
is( $iso->offset, 0, "Offset?");

is( $iso->year, 1971, 'year()' );
is( $iso->month, 10, 'month()' );
is( $iso->day, 25, 'day()' );

is( $iso->iso_year, 1971, 'iso_year()' );
is( $iso->iso_week, 43, 'iso_week()' );
is( $iso->iso_week_day, 1, 'iso_week_day()' );

$date = timegm(0,0,0,28,3,2001);
$iso = Date::ISO->new( epoch => $date, offset => 0 );
is( $iso->offset, 0, "Offset?");

is( $iso->year, 2001, 'year()');
is( $iso->month, 4, 'month()' );
is( $iso->day, 28, 'day()' );

is( $iso->iso_year, 2001, 'iso_year()' );
is( $iso->iso_week, 17, 'iso_week()' );
is( $iso->iso_week_day, 6, 'iso_week_day()' );


