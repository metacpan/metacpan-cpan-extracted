#!/usr/bin/perl

# Unit testing for Data::Vitals::Waist

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Data::Vitals::Waist;





#####################################################################
# Constructor

my $Waist = Data::Vitals::Waist->new('38"');
isa_ok( $Waist, 'Data::Vitals::Waist' );
is( $Waist->as_string,   '97cm', 'Returned correct string form'   );
is( $Waist->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Waist->as_imperial, '38"',  'Returned correct imperial form' );
is( $Waist->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Waist->as_inches,   '38"',  'Returned original size'         );
