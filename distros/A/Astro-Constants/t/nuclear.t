use Test::More;
use Astro::Constants qw( :nuclear precision );

	unlike(SPEED_LIGHT, qr/\d/, "Shouldn't import SPEED_LIGHT with :nuclear");
	unlike(JANSKY, qr/\d/, "Shouldn't import JANSKY with :nuclear");
	is(THOMSON_CROSS_SECTION, 6.6524587321e-29, 'THOMSON_CROSS_SECTION');
	is(MASS_ELECTRON, 9.1093837015e-31, 'MASS_ELECTRON');
	is(MASS_PROTON, 1.67262192369e-27, 'MASS_PROTON');
	is(MASS_NEUTRON, 1.67492749804e-27, 'MASS_NEUTRON');
	is(RADIUS_ELECTRON, 2.8179403262e-15, 'RADIUS_ELECTRON');
	is(RADIUS_BOHR, 5.29177210903e-11, 'RADIUS_BOHR');

	is(MASS_ALPHA, 6.6446573357e-27, 'MASS_ALPHA');

diag "MASS_HYDROGEN is from IUPAC 2013";
TODO: {
	local $TODO = "haven't implemented 'relative' uncertainties in method yet";

	cmp_ok(precision('MASS_HYDROGEN', 'relative'), '==', 0.0002, 
		'relative uncertainty of H mass');
};
cmp_ok(precision('MASS_HYDROGEN'), '==', 3.3e-31, 
	'absolute uncertainty of H mass');

my $h_abs = precision('MASS_HYDROGEN');
my $p_plus_e = MASS_PROTON + MASS_ELECTRON;
cmp_ok($p_plus_e, '<', MASS_HYDROGEN + $h_abs, 
	'Is proton + electron less than the upper bound on mass hydrogen');
cmp_ok($p_plus_e, '>', MASS_HYDROGEN - $h_abs, 
	'Is proton + electron greater than the lower bound on mass hydrogen');

done_testing();
