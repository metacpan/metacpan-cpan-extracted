#!/usr/bin/perl

# Unit testing for Data::Vitals::Underarm

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Data::Vitals::Underarm;





#####################################################################
# Constructor

my $Underarm = Data::Vitals::Underarm->new('38"');
isa_ok( $Underarm, 'Data::Vitals::Underarm' );
is( $Underarm->as_string,   '97cm', 'Returned correct string form'   );
is( $Underarm->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Underarm->as_imperial, '38"',  'Returned correct imperial form' );
is( $Underarm->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Underarm->as_inches,   '38"',  'Returned original size'         );
