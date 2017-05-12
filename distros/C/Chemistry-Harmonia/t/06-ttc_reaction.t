use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test ttc_reaction() #####

my $dt = &datest;

for my $mix ( keys %$dt ){
    my $ce = parse_chem_mix( $mix );

    is_deeply( ttc_reaction( $ce ),
		$dt->{$mix}, "TTC test '$mix'" );
}

exit;

sub datest{
    return {
    '2 KMnO4 + 5 H2O2 + 3 H2SO4 --> 1 K2SO4 + 2 MnSO4 + 8 H2O + 5 O2' =>
	{
          'r' => 5,
          'a' => 5,
          's' => 7
        },
    '10 [Cr(CO(NH2)2)6]4[Cr(CN)6]3 + 1176 KMnO4 + 1399 H2SO4 --> 35 K2Cr2O7 + 660 KNO3 + 420 CO2 + 223 K2SO4 + 1176 MnSO4 + 1879 H2O' =>
	{
          'r' => 8,
          'a' => 8,
          's' => 9
        },
    }
}
