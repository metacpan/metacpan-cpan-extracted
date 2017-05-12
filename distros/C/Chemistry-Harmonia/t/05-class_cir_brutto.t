use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test class_cir_brutto() #####

my $dt = &datest;

for my $mix ( keys %$dt ){
    my %k;
    my $ce = parse_chem_mix( $mix, \%k );

    is_deeply( [ @{ class_cir_brutto( $ce, \%k ) } ],
		[ @{ $dt->{$mix} } ], "CLASS-CIR test '$mix'" );
}


exit;

sub datest{
    return {
    '2 KMnO4 + 5 H2O2 + 3 H2SO4 --> 1 K2SO4 + 2 MnSO4 + 8 H2O + 5 O2' =>
	[ 'HKMnOS', 1504979632,
          {
            'O2' => 'O2',
            'MnSO4' => 'Mn1O4S1',
            'KMnO4' => 'K1Mn1O4',
            'K2SO4' => 'K2O4S1',
            'H2SO4' => 'H2O4S1',
            'H2O2' => 'H2O2',
            'H2O' => 'H2O1'
          }
        ],
    '10 [Cr(CO(NH2)2)6]4[Cr(CN)6]3 + 1176 KMnO4 + 1399 H2SO4 --> 35 K2Cr2O7 + 660 KNO3 + 420 CO2 + 223 K2SO4 + 1176 MnSO4 + 1879 H2O' =>
	[ 'CCrHKMnNOS', 645245094,
          {
            'KNO3' => 'K1N1O3',
            'MnSO4' => 'Mn1O4S1',
            'K2Cr2O7' => 'Cr2K2O7',
            'H2SO4' => 'H2O4S1',
            'H2O' => 'H2O1',
            '[Cr(CO(NH2)2)6]4[Cr(CN)6]3' => 'C42Cr7H96N66O24',
            'CO2' => 'C1O2',
            'KMnO4' => 'K1Mn1O4',
            'K2SO4' => 'K2O4S1'
          }
        ],

    }
}
