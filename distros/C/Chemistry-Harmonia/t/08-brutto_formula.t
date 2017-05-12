use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test brutto_formula() #####

my $dt = &datest;

for my $f ( keys %$dt ){
    is_deeply( brutto_formula( $f ), $dt->{ $f }, "gross_formula test '$f'" );
}

exit;

sub datest{
    return {
	'[Cr(CO(NH2)2)6]4[Cr(CN)6]3' => 'C42Cr7H96N66O24',
	'{(NH4)6[MnMo9O32]}{H2O}30' => 'H84Mn1Mo9N6O62',
	'{Pb(CH3COO)2}{H2O}3' => 'C4H12O7Pb1',
    }
}
