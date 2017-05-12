#
# Test the academic_week subroutine
#

use strict;
use warnings;

use Test::More;
use Test::Exception;
use blib;
use DateTime;
use DateTime::Calendar::WarwickUniversity;

my %dates = (
	'2006-01-02'	=> 11,
	'2006-11-12'	=> 6,
	'2006-11-13'	=> 7,
	'2007-01-10'	=> 11,
);

plan tests => keys(%dates) + 1;

# Test existence
can_ok('DateTime::Calendar::WarwickUniversity', 'term_week');

#
# Test output
#

while( my($in, $expected) = each %dates ) {
	my ($year, $month, $day) = split(/-/, $in);
	my $dt_in = DateTime::Calendar::WarwickUniversity->new(
		year => $year,
		month => $month,
		day => $day
	);

	my $week_out = $dt_in->term_week;

	is( $week_out, $expected,
		"Result is the expected term week for $dt_in" );
}

