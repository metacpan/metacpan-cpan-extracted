#!/usr/bin/perl

# Unit testing for Data::Vitals::Hips

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Data::Vitals::Hips;





#####################################################################
# Constructor

my $Hips = Data::Vitals::Hips->new('38"');
isa_ok( $Hips, 'Data::Vitals::Hips' );
is( $Hips->as_string,   '97cm', 'Returned correct string form'   );
is( $Hips->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Hips->as_imperial, '38"',  'Returned correct imperial form' );
is( $Hips->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Hips->as_inches,   '38"',  'Returned original size'         );

exit(0);