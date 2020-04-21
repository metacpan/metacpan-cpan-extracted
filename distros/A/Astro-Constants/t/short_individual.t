use strict;
use Test::More;
use Astro::Constants::MKS qw/ $A_c $A_k /;

	is($A_c, 299_792_458, 'SPEED_LIGHT');
	is($A_k, 1.380649e-23, 'BOLTZMANN');

done_testing();
