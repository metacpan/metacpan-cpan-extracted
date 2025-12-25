use strict;
use v5.28;
package App::puzzl::run;

use Exporter 'import';
use Module::Load;

sub run_day {
	my ($day) = @_;

	if($day eq 'all') {
		my @days = glob("days/day*.pl");
		foreach my $day_found (@days) {
			run($day_found);
		}
		return;
	}

	open(my $input_fh, "<", "input/day$day.txt") or die "failed to open input file input/day$day.txt";
	do "./days/day$day.pl";
	say '=== PART 1 ===';
	part1($input_fh);

	seek($input_fh, 0, 0);
	say '=== PART 2 ===';
	part2($input_fh);

	close($input_fh);
}

our @EXPORT_OK = qw(run_day);

1;