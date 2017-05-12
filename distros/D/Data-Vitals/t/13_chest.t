#!/usr/bin/perl

# Unit testing for Data::Vitals::Chest

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Data::Vitals::Chest;





#####################################################################
# Constructor

my $Chest = Data::Vitals::Chest->new('38"');
isa_ok( $Chest, 'Data::Vitals::Chest' );
is( $Chest->as_string,   '97cm', 'Returned correct string form'   );
is( $Chest->as_metric,   '97cm', 'Returned correct metric form'   );
is( $Chest->as_imperial, '38"',  'Returned correct imperial form' );
is( $Chest->as_cms,      '97cm', 'Returned correct cm size'       );
is( $Chest->as_inches,   '38"',  'Returned original size'         );
