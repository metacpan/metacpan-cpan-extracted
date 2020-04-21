use strict;
use Test::More;
use Astro::Constants::MKS qw/:short/;

	is($A_c, 299_792_458, 'SPEED_LIGHT');
	is($A_k, 1.380649e-23, 'BOLTZMANN');
	is($A_G, 6.6743e-11, 'GRAVITATIONAL');
	is($A_eV, 1.602176634e-19, 'ELECTRON_VOLT');
	is($A_h, 6.62607015e-34, 'PLANCK');
	is($A_hbar, 1.0545718176763e-34, 'H_BAR');
	is($A_e, 1.602176634e-19, 'CHARGE_ELEMENTARY');

	is($A_sigma, 5.670374419e-08, 'STEFAN_BOLTZMANN');
	is($A_arad, 7.565723e-16, 'DENSITY_RADIATION');
	is($A_Wien, 0.002897771955, 'WIEN');
	is($A_alpha, 0.0072973525693, 'ALPHA');
	is($A_Z0, 376.730_313_461, 'VACUUM_IMPEDANCE');
	is($A_eps0, 8.8541878128e-12, 'PERMITIVITY_0');
	is($A_mu0, 1.25663706212e-06, 'PERMEABILITY_0');

	isnt($A_c, 299_792_459, 'incorrect SPEED_LIGHT');

done_testing();
