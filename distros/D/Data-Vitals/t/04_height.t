#!/usr/bin/perl

# Unit testing for Data::Vitals::Height

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Data::Vitals::Height;





#####################################################################
# Constructor

my $Height = Data::Vitals::Height->new("6'0\"");
isa_ok( $Height, 'Data::Vitals::Height' );
is( $Height->as_string,   '183cm', 'Returned correct string form'    );
is( $Height->as_metric,   '183cm', 'Returned correct metric value'   );
is( $Height->as_imperial, "6'0\"", 'Returned correct imperial value' );
is( $Height->as_cms,      '183cm', 'Returned correct cm size'        );
is( $Height->as_feet,     "6'0\"", 'Returned original size'          );
