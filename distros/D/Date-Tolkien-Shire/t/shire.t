package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire;
use Test::More 0.47;	# The best we can do with 5.6.2.
use Time::Local;

plan tests => 2567;

my @month_length = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

for my $year ( 1999 .. 2002, 2035 .. 2037 ) {
    $month_length[1] = $year % 4 ? 28 :
	$year % 100 ? 29 :
	$year % 400 ? 28 : 29;
    for my $month ( 0 .. 11 ) {
	for my $day ( 1 .. $month_length[$month] ) {
	    my $ymd = sprintf '%04d-%02d-%02d', $year, $month + 1, $day;
	    my $time = timelocal( 0, 0, 0, $day, $month, $year );
	    if ( my $date = Date::Tolkien::Shire->new( $time ) ) {
		cmp_ok( $date->time_in_seconds(), '==', $time,
		    "new() for $ymd" );
	    } else {
		fail( "new() for $ymd failed: " .
		    Date::Tolkien::Shire->error() );
	    }
	}
    }
}

{
    my $date1 = Date::Tolkien::Shire->new(
	timelocal( 0, 0, 0, 31, 11, 2037 ) );

    cmp_ok( $date1->year(), '==', 7502,
	'2037-12-31 is Shire year 7502' );

    cmp_ok( $date1->month(), 'eq', 'Afteryule',
	'2037-12-31 is month Afteryule' );

    cmp_ok( $date1->__fmt_shire_month(), '==', 1,
	'2037-12-31 is month 1 of the Shire calendar' );

    cmp_ok( $date1->day(), '==', 9, '2037-12-31 is day 9 of Afteryule' );

    cmp_ok( $date1->weekday(), 'eq', 'Monday', '2037-12-31 is Monday' );

    cmp_ok( $date1->__fmt_shire_day_of_week(), '==', 3,
	'2037-12-21 is day 3 of the Shire week' );

    cmp_ok( $date1->trad_weekday(), 'eq', 'Monendei',
	'2037-12-31 is Monendei (traditional)' );

    is( $date1->on_date(), "Monday 9 Afteryule 7502\n",
	'2037-12-31 is Monday 9 Afteryule 7502' );

    my $date2 = Date::Tolkien::Shire->new( $date1 );

    cmp_ok( $date2, '==', $date1, 'Instantiate from another object' );

    $date2 = Date::Tolkien::Shire->from_shire(
	year	=> 7502,
	month	=> 1,
	day	=> 9,
    );

    cmp_ok( $date2, '==', $date1, 'Instantiate from Shire date' )
	or diag( "Error: $Date::Tolkien::Shire::ERROR" );

}

1;

# ex: set textwidth=72 :
