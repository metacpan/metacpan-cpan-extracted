#!perl -T

use strict;
use Test::More;
use Astro::Constants::MKS qw/ALPHA DENSITY_RADIATION DENSITY_CRITICAL_RHOc SPEED_LIGHT 
		GRAVITATIONAL PARSEC ASTRONOMICAL_UNIT HUBBLE_TIME PI STEFAN_BOLTZMANN
		IMPEDANCE_VACUUM
	/;

ok(1, 'No testing here yet');

is_within( ALPHA, 1/137.035999139, 4.1e-10, 'fine structure constant to within 4.1e-10');

# now rho_c is 3*H^2/8*PI*G
my $hubble_constant = 100 * 1e3 / 1e6 / PARSEC;	# +/-0.77, 2013-03-21 Planck Mission

is_within( HUBBLE_TIME, 1/$hubble_constant, 1.3e-4, 
	'Hubble time is the inverse of the hubble constant');

is_within( DENSITY_RADIATION, 4 * STEFAN_BOLTZMANN / SPEED_LIGHT, 2.3e-6,
	'The radiation density constant is defined as a = 4 * sigma /c');

is_within( DENSITY_CRITICAL_RHOc, 3 /(8 * PI * GRAVITATIONAL * 100 * PARSEC**2), 5e-5,
	'critical density of the universe, rho_c, divided by the dimensionless Hubble parameter squared');

is_within( PARSEC, 648_000 * ASTRONOMICAL_UNIT/PI, 1e-11,
	'definition of a parsec is 648000/pi AU');

cmp_ok(IMPEDANCE_VACUUM, '!=', 0, 'should throw an error on using an non-imported constant');



done_testing();

sub is_within {
	my ($found, $given, $precision, $description) = @_;

	# what is default behaviour?
	my $relative_difference = abs(($found - $given)/$found);
	cmp_ok($relative_difference, '<=', $precision, $description);

	# should produce good TAP on error like
	# $found not within $precision of $given
}
