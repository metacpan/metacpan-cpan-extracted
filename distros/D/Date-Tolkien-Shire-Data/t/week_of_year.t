package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __week_of_year };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 366;

my $want;
my $count;
my @holiday_week = ( undef, 1, 26, 0, 0, 27, 52 );

foreach my $spec (
    [  0, 1,  1 ],
    [  1, 1, 30 ],
    [  2, 1, 30 ],
    [  3, 1, 30 ],
    [  4, 1, 30 ],
    [  5, 1, 30 ],
    [  6, 1, 30 ],
    [  0, 2,  5 ],
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
	if ( $month ) {
	    $count++ % 7
		or $want++;
	} else {
	    $want = $holiday_week[$day]
		and $count++;
	}
	my $title = $month ? "Month $month, day $day" : "Holiday $day";
	is( __week_of_year( $month, $day ), $want, $title );
    }
}

1;

# ex: set textwidth=72 :
