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
	'2006-01-02'	=> [2, 1],
	'2006-11-12'	=> [1, 6],
	'2006-11-13'	=> [1, 7],
	'2007-01-10'	=> [2, 1],
);

plan tests => keys(%dates) + 1;

# Test existence
can_ok('DateTime::Calendar::WarwickUniversity', 'term_and_week');

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

	my @week_out = $dt_in->term_and_week;

	is_deeply( \@week_out, $expected,
		"Result is the expected term and week for $dt_in" );
}

