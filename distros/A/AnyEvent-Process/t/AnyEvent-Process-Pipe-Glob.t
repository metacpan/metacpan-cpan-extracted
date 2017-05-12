use strict;

use Test::More tests => 5;

use_ok('AnyEvent::Process');

my $proc = new AnyEvent::Process(
	fh_table => [
		\*STDIN  => ['pipe', '<', \*OUTPIPE],
		\*STDOUT => ['pipe', '>', \*INPIPE]
	],
	code => sub {
		my $line = <>;
		print eval $line;
		exit 0;
	});

for (1 .. 3) {
	$proc->run();

	my $math = "13 + 25 + $_";
	print OUTPIPE $math, "\n";
	close OUTPIPE;

	my $result = eval $math;
	my $child_result = <INPIPE>;

	is($child_result, $result, "Compute '$math' in the child, communicate over pipes");
}

$proc->run(code => sub {
		my $line = <>;
		print eval "2*($line)";
		exit 0;
	});

my $math = "17 - 5";
print OUTPIPE $math, "\n";
close OUTPIPE;

my $result = eval $math;
my $child_result = <INPIPE>;

is($child_result, 2 * $result, "Compute double of '$math' in the child, communicate over pipes");
