use Test::More;
use Astro::Constants::MKS qw/:nuclear/;

	unlike(SPEED_LIGHT, qr/\d/, "Shouldn't import SPEED_LIGHT with :nuclear");
	unlike(JANSKY, qr/\d/, "Shouldn't import JANSKY with :nuclear");
	is(THOMSON_CROSS_SECTION, 0.665_245_871_58e-28, 'THOMSON_CROSS_SECTION');
	is(MASS_ELECTRON, 9.109_383_56e-31, 'MASS_ELECTRON');
	is(MASS_PROTON, 1.672_621_898e-27, 'MASS_PROTON');
	is(MASS_NEUTRON, 1.674_927_471e-27, 'MASS_NEUTRON');
	is(RADIUS_ELECTRON, 2.817_940_3227e-15, 'RADIUS_ELECTRON');
	is(RADIUS_BOHR, 0.529_177_210_67e-10, 'RADIUS_BOHR');

	is(MASS_ALPHA, 6.644_657_230e-27, 'MASS_ALPHA');

done_testing();
