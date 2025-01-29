use Test::More;

use Colouring::In::XS;
for my $i (0 .. 10000) {
	my $colour = Colouring::In::XS->new('hsla(' . $i . ', 100, 50, 1)');
	for ($colour->colour()) {
		if ($_ > 255) {
			ok(0);
		}
	}
}

ok(1);

done_testing;

