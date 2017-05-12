#!perl -T

use warnings;
use strict;
use Test::More;
use Astro::Constants::MKS qw/STEFAN_BOLTZMANN SPEED_LIGHT 
	ALPHA GRAVITATIONAL PI PARSEC ASTRONOMICAL_UNIT
	PLANCK H_BAR PERMEABILITY_0
	/;



is( ALPHA, sprintf("%.13f", 1/137.035999139), 'fine structure constant to within 2.3e-10');

# now rho_c is 3*H^2/8*PI*G
my $hubble_constant = 67.80;	# +/-0.77, 2013-03-21 Planck Mission

#is( HUBBLE_TIME, 1/$hubble_constant, 'Hubble time is the inverse of the hubble constant');

cmp_ok( abs(PARSEC - (648_000 * ASTRONOMICAL_UNIT/PI)), '<', 13675, 'definition of a parsec is 648000/pi AU');

is_within(H_BAR, PLANCK/(2 * PI), 1.2e-8, "H_BAR is Planck's constant over 2 Pi");

is_within(PERMEABILITY_0, 4e-7 * PI, 1e-10, 'Permeability of free space, mu_0, is 4 Pi x 10-7');

done_testing();

sub is_within {
    my ($found, $given, $precision, $description) = @_;

	unless ($found && $given && $precision) {
		warn "Failed $description: no parameters " unless $found && $given && $precision;
		return undef;
	}

    # what is default behaviour?
    my $relative_difference = $found ? abs(($found - $given)/$found)
									: abs(($found - $given)/$given);
    cmp_ok($relative_difference, '<=', $precision, $description);

    # should produce good TAP on error like
    # $found not within $precision of $given
}
