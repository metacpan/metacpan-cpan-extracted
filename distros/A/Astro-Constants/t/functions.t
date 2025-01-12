use Test::More;
use Astro::Constants qw( :all pretty precision );

can_ok('Astro::Constants', qw/pretty precision/);

like( pretty(SPEED_LIGHT), qr/\d\.\d{2,5}([Ee][+-]?\d+)?$/, 'SPEED_LIGHT to 3 sig figs');
like( pretty(BOLTZMANN), qr/\d\.\d{2,5}([Ee][+-]?\d+)?$/, 'BOLTZMANN to 3 sig figs');
is( pretty(GRAVITATIONAL), 6.674e-11, 'GRAVITATIONAL rounded to 3 sig figs');
is( pretty(ELECTRON_VOLT), 1.602e-19, 'ELECTRON_VOLT rounded to 3 sig figs');

is( precision('GRAVITATIONAL'), 2.2e-5, 'relative uncertainty in GRAVITATIONAL');
is( precision('MASS_EARTH'), 6e20, 'absolute uncertainty in MASS_EARTH');

TODO: {
	local $todo = q/need to descern between absolute and relative precision/;

	is( precision('GRAVITATIONAL'), 2.2e-5, 'relative uncertainty in GRAVITATIONAL');
	is( precision('MASS_EARTH'), 6e20, 'absolute uncertainty in MASS_EARTH');

}

done_testing();
