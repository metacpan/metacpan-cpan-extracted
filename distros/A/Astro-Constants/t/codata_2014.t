use strict;
use Test::More skip_all => 'waiting for Astro::Constants::CODATA::2014';
use Astro::Constants::MKS qw/:long/;

skip
diag("Testing values from CODATA 2014");

subtest fundamental => sub {
	is(SPEED_LIGHT, 299_792_458, 'SPEED_LIGHT');
	is(BOLTZMANN, 1.380_648_52e-23, 'BOLTZMANN');
	is(GRAVITATIONAL, 6.674_08e-11, 'GRAVITATIONAL');
	is(ELECTRON_VOLT, 1.602_176_6208e-19, 'ELECTRON_VOLT');
	is(PLANCK, 6.626_070_040e-34, 'PLANCK');
	is(H_BAR, 1.054_571_800e-34, 'H_BAR');
	is(ELECTRON_CHARGE, 1.602_176_6208e-19, 'ELECTRON_CHARGE');

	is(STEFAN_BOLTZMANN, 5.670_367e-8, 'STEFAN_BOLTZMANN');
	is(DENSITY_RADIATION, 7.565723e-16, 'DENSITY_RADIATION');
	is(WIEN, 2.897_7729e-3, 'WIEN');
	is(ALPHA, 7.297_352_5664e-3, 'ALPHA');
	is(IMPEDANCE_VACUUM, 376.730_313_461, 'IMPEDANCE_VACUUM');
	is(PERMITIV_FREE_SPACE, 8.854_187_817e-12, 'PERMITIV_FREE_SPACE');
	is(PERMEABL_FREE_SPACE, 12.566_370_614e-7, 'PERMEABL_FREE_SPACE');
};

subtest conversion => sub {
	is(ATOMIC_MASS_UNIT, 1.660_539_040e-27, 'ATOMIC_MASS_UNIT');
	is(AVOGADRO, 6.022_140_857e23, 'AVOGADRO');
};

subtest nuclear => sub {
	is(THOMSON_CROSS_SECTION, 0.665_245_871_58e-28, 'THOMSON_CROSS_SECTION');
	is(MASS_ELECTRON, 9.109_383_56e-31, 'MASS_ELECTRON');
	is(MASS_PROTON, 1.672_621_898e-27, 'MASS_PROTON');
	is(MASS_NEUTRON, 1.674_927_471e-27, 'MASS_NEUTRON');
	is(RADIUS_ELECTRON, 2.817_940_3227e-15, 'RADIUS_ELECTRON');
	is(RADIUS_BOHR, 0.529_177_210_67e-10, 'RADIUS_BOHR');

	# mass of the alpha particle is not in Astroconst
	is(MASS_ALPHA, 6.644_657_230e-27, 'MASS_ALPHA');
};

TODO: {
	local $TODO = 'When all the constants are tested, remove the write bit';

	ok( ! -w "t/mks.t", "For safety, this test file should be read-only.");
}

done_testing();
