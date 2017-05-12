package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __date_to_day_of_year
    __day_of_year_to_date
    __is_leap_year
};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 2193;

foreach my $year ( 1419, 1420 ) {
    my $is_leap = __is_leap_year( $year );
    print "# $year is ", ( $is_leap ? '' : 'not ' ), "a leap year\n";
    my $want = 1;
    foreach my $spec (
	[  0, 1,  1 ],
	[  1, 1, 30 ],
	[  2, 1, 30 ],
	[  3, 1, 30 ],
	[  4, 1, 30 ],
	[  5, 1, 30 ],
	[  6, 1, 30 ],
	[  0, 2,  3 ],
	( $is_leap ? [  0, 4,  4 ] : () ),
	[  0, 5,  5 ],
	[  7, 1, 30 ],
	[  8, 1, 30 ],
	[  9, 1, 30 ],
	[ 10, 1, 30 ],
	[ 11, 1, 30 ],
	[ 12, 1, 30 ],
	[  0, 6,  6 ],
    ) {
	my ( $month, $start, $finish ) = @{ $spec };
	for ( my $day = $start; $day <= $finish; $day++ ) {
	    my $title = 'Day of year for ' . (
		$month ? "Year $year, month $month, day $day" :
		"Year $year, holiday $day" );
	    my $yd = __date_to_day_of_year( $year, $month, $day );
	    is( $yd, $want++, $title );
	    my ( $m, $d ) = __day_of_year_to_date( $year, $yd );
	    is( $m, $month, "Month for year $year, day of year $yd" );
	    is( $d, $day, "Day for year $year, day of year $yd" );
	}
    }
}

1;

# ex: set textwidth=72 :
