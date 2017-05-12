package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{ __day_of_week };
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

plan tests => 366;

my $want;
my @holiday_want = ( undef, 1, 7, 0, 0, 1, 7 );

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
	my $title = $month ? "Month $month, day $day" : "Holiday $day";
	$want = $month ? $want % 7 + 1 : $holiday_want[$day];
	is( __day_of_week( $month, $day ), $want, $title );
    }
}

1;

# ex: set textwidth=72 :
