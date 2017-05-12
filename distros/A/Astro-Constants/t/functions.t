use Test::More;
use Astro::Constants::MKS qw/:long pretty/;

like( pretty(SPEED_LIGHT), qr/\d\.\d{2,5}([Ee][+-]?\d+)?$/, 'SPEED_LIGHT to 5 sig figs');
like( pretty(BOLTZMANN), qr/\d\.\d{2,5}([Ee][+-]?\d+)?$/, 'BOLTZMANN to 5 sig figs');
is( pretty(GRAVITATIONAL), 6.674_08e-11, 'GRAVITATIONAL rounded to 5 sig figs');
is( pretty(ELECTRON_VOLT), 1.602_18e-19, 'ELECTRON_VOLT rounded to 5 sig figs');

TODO: {
	local $todo = q/need to implement 'precision'/;
}

done_testing();
