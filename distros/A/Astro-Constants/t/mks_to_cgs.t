#!perl -T

use Test::More;
use Astro::Constants::CGS qw/CHARGE_ELEMENTARY SPEED_LIGHT /;

note("When functioning, this test suite will check that the MKS and CGS versions of each constant are equivalent");
note("TODO: get the MKS values from the MKS module");

my $charge_elementary_mks = 1.6021766208e-19;
is( sprintf("%.9e", CHARGE_ELEMENTARY), 
	sprintf("%.9e", $charge_elementary_mks * SPEED_LIGHT/10), 'elementary charge conversion');


done_testing();
