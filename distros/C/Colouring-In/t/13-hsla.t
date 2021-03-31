use Test::More;

use Colouring::In;
for my $i (0 .. 10000) {
	my $colour = Colouring::In->new('hsla(' . $i . ', 100, 50, 1)');
	for ($colour->colour()) {
		if ($_ > 255) {
			ok(0);
		}
	}
}

ok(my $colour = Colouring::In->new('hsla(60, 100, 50, 1)'));
is_deeply([$colour->colour()], [255,255,0]);

done_testing;

