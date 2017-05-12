use strict;
use Test::More;
use Astro::Constants::MKS qw/:short/;

	is($A_c, 299_792_458, 'SPEED_LIGHT');
	is($A_k, 1.380_648_52e-23, 'BOLTZMANN');
	is($A_G, 6.674_08e-11, 'GRAVITATIONAL');
	is($A_eV, 1.602_176_6208e-19, 'ELECTRON_VOLT');
	is($A_h, 6.626_070_040e-34, 'PLANCK');
	is($A_hbar, 1.054_571_800e-34, 'H_BAR');
	is($A_e, 1.602_176_6208e-19, 'CHARGE_ELEMENTARY');

	is($A_sigma, 5.670_367e-8, 'STEFAN_BOLTZMANN');
	is($A_arad, 7.565723e-16, 'DENSITY_RADIATION');
	is($A_Wien, 2.897_7729e-3, 'WIEN');
	is($A_alpha, 7.297_352_5664e-3, 'ALPHA');
	is($A_Z0, 376.730_313_461, 'VACUUM_IMPEDANCE');
	is($A_eps0, 8.854_187_817e-12, 'PERMITIVITY_0');
	is($A_mu0, 12.566_370_614e-7, 'PERMEABILITY_0');

	isnt($A_c, 299_792_459, 'incorrect SPEED_LIGHT');

done_testing();
