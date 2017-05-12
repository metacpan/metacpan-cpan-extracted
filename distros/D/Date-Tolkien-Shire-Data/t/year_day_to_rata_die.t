package main;

use 5.006002;

use strict;
use warnings;

use Date::Tolkien::Shire::Data qw{
    __year_day_to_rata_die
    __rata_die_to_year_day
    __is_leap_year
};
use POSIX ();
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

use constant TOP_YEAR	=> 400;

# I find that on my system, a full round-trip test of every day in the
# 400-year calendar cycle takes ~37 wall clock seconds. My experience is
# that the last day of the year is the hard one to get right, and it
# takes a fraction of a second. So the ordinary test just does the last
# day, but for formal author testing we do them all.
#
# This would all be a lot simpler if I could go as far as Test::More
# 0.88 and use done_testing(), instead of computing how many tests I
# intend to run. But unfortunately I can not do that while targeting
# Perl 5.6.2, which I feel like I have to for the sake of
# Date::Tolkien::Shire.

my $days_tested = $ENV{AUTHOR_TESTING} ?
    TOP_YEAR * 365 + POSIX::floor( TOP_YEAR / 4 ) -
	POSIX::floor( TOP_YEAR / 100 ) + POSIX::floor( TOP_YEAR / 400 ) :
    TOP_YEAR;
my $want_rd = 0;

plan tests => $days_tested * 3 + 1;

foreach my $year ( 1 .. TOP_YEAR ) {

    my $day_end = 365 + __is_leap_year( $year );
    my $day_start = $ENV{AUTHOR_TESTING} ? 1 : $day_end;

    foreach my $day ( $day_start .. $day_end ) {

	$want_rd += $day_start;

	my $rata_die = __year_day_to_rata_die( $year, $day );
	cmp_ok( $rata_die, '==', $want_rd,
	    "Year $year day $day is Rata Die $want_rd" );

	my ( $yr, $da ) = __rata_die_to_year_day( $rata_die );
	cmp_ok( $yr, '==', $year, "Rata Die $rata_die is year $year" );
	cmp_ok( $da, '==', $day, "Rata Die $rata_die is day $day of $year" );
    }
}

cmp_ok( __year_day_to_rata_die( -4065, 1 ), '==', -1485076,
    'Ensure __year_day_to_rata_die() takes negative years' );

1;

# ex: set textwidth=72 :
