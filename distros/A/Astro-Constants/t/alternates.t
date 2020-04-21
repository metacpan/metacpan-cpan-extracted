use strict;
use Test::More;
use Astro::Constants::MKS qw/:long :alternates/;

# test that all of a constant's alternate values are included

is(SPEED_LIGHT, 299_792_458, 'SPEED_LIGHT');
is(LIGHT_SPEED, 299_792_458, 'LIGHT_SPEED');

my $charge_e = 1.602_176_634e-19;
is(CHARGE_ELEMENTARY, $charge_e, 'CHARGE_ELEMENTARY');
is(ELECTRON_CHARGE, $charge_e, 'ELECTRON_CHARGE');

my $e0 = 8.854_187_812_8e-12;
is(PERMITIV_FREE_SPACE, $e0, 'PERMITIV_FREE_SPACE');
is(PERMITIVITY_0, $e0, 'PERMITIVITY_0');

my $m0 = 1.256_637_062_12e-6;
is(PERMEABL_FREE_SPACE, $m0, 'PERMEABL_FREE_SPACE');
is(PERMEABILITY_0, $m0, 'PERMEABILITY_0');
is(CONSTANT_MAGNETIC, $m0, 'CONSTANT_MAGNETIC');

done_testing();
