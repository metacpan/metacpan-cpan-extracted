use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw( :all );

##### Test stoichiometry() #####

&_ts( &datest, { }, '' );

&_ts( 
    {
	'KMnO4 + H2O2 + H2SO4 --> K2SO4 + MnSO4 + H2O + O2' =>
	[
          '2 H2O + 3 H2SO4 + 2 KMnO4 == 5 H2O2 + 1 K2SO4 + 2 MnSO4',
          '6 H2SO4 + 4 KMnO4 == 6 H2O + 5 O2 + 2 K2SO4 + 4 MnSO4',
          '2 H2O2 == 2 H2O + 1 O2',
          '3 H2SO4 + 2 KMnO4 == 3 H2O2 + 1 O2 + 1 K2SO4 + 2 MnSO4'
	],
	'Cu2S + H2O + O2 + SO2 = CuSO4 + H2SO4' =>
	[
	    '6 H2SO4 + 1 Cu2S == 6 H2O + 2 CuSO4 + 5 SO2',
	    '2 H2SO4 + 5 O2 + 2 Cu2S == 2 H2O + 4 CuSO4',
	    '3 O2 + 1 Cu2S + 1 SO2 == 2 CuSO4',
	    '2 H2O + 1 O2 + 2 SO2 == 2 H2SO4'
	],
    },
    { 'redox_pairs' => 0 }, "with 'redox_pairs' = 0" );

&_ts( 
    {
	'PbS + O3 --> PbSO4 + O2' =>
	[
          '4 O3 + 1 PbS == 4 O2 + 1 PbSO4'
	],
    },
    { 'coefficients'=>{ 'O3' => 4, 'O2' => 4 } }, "with 'coefficients'" );


exit;

sub _ts{
    my( $dt, $op, $msg ) = @_;

    for my $mix ( keys %$dt ){
	is_deeply( [ sort( map{
			my %k;
			my $ccn = class_cir_brutto( parse_chem_mix( $_, \%k ), \%k );
			"$ccn->[0]$ccn->[1]";
			} @{ stoichiometry( $mix, $op ) }
		) ],
		[ sort( map{
			my %k;
			my $ccn = class_cir_brutto( parse_chem_mix( $_, \%k ), \%k );
			"$ccn->[0]$ccn->[1]";
			} @{ $dt->{$mix} }
		) ], "Stoichiometry test '$mix' $msg" );

	$op->{'coefficients'} = { };	# Сбрасываем опции
    }
}

sub datest{
    return {
    # ПЕРЕОПРЕДЕЛЁННЫЕ системы
    'Na3PO4 + AgNO3 --> Ag3PO4 + NaNO3' =>
	[
	    '1 Na3PO4 + 3 AgNO3 == 1 Ag3PO4 + 3 NaNO3'
        ],
    'LiNa3(MoO4)2 + Na4F2MoO4 --> Na2MoO4 + Li2F2' =>
	[
	    '1 Na4F2MoO4 + 2 LiNa3(MoO4)2 == 1 Li2F2 + 5 Na2MoO4'
        ],
    'Ba[Zr(C2O4)2CO3] --> Ba[Zr(C2O4)(CO3)2] + CO' =>
	[
	    '1 Ba[Zr(C2O4)2CO3] == 1 Ba[Zr(C2O4)(CO3)2] + 1 CO'
        ],
    # НЕДООПРЕДЕЛЁННЫЕ системы
    'AgNO3 + PH3 + H2O --> Ag + H3PO4 + HNO3' =>
	[
	    '1 PH3 + 4 H2O + 8 AgNO3 == 8 Ag + 1 H3PO4 + 8 HNO3'
        ],
    '[Cr(CO(NH2)2)6]4[Cr(CN)6]3, KMnO4, H2SO4, K2Cr2O7, KNO3, CO2, K2SO4, MnSO4, H2O' =>
	[
	    '1399 H2SO4 + 10 [Cr(CO(NH2)2)6]4[Cr(CN)6]3 + 1176 KMnO4 == 1879 H2O + 660 KNO3 + 35 K2Cr2O7 + 420 CO2 + 1176 MnSO4 + 223 K2SO4'
	],
    'Na4[Fe(CN)6] NaMnO4 H2SO4 NaHSO4 Fe2(SO4)3 MnSO4 HNO3 CO2 H2O' =>
	[
	    '299 H2SO4 + 10 Na4[Fe(CN)6] + 122 NaMnO4 == 162 NaHSO4 + 188 H2O + 60 HNO3 + 60 CO2 + 122 MnSO4 + 5 Fe2(SO4)3'
        ],
    # ОПРЕДЕЛЁННЫЕ системы
    'H2SO4 + NaOH --> Na2SO4 + H2O' =>
	[
          '2 NaOH + 1 H2SO4 == 2 H2O + 1 Na2SO4'
        ],
    'NH4NO3 --> N2O + H2O' =>
	[
	    '1 NH4NO3 == 2 H2O + 1 N2O'
        ],
    # Others с множеством решений
    'MoO3 + K2CO3 + S --> MoS2 + K2O + CO2 + SO2' =>
	[
	    '1 K2CO3 == 1 K2O + 1 CO2',
	    '2 MoO3 + 7 S == 3 SO2 + 2 MoS2'
        ],
    'KMnO4 + H2O2 + H2SO4 --> K2SO4 + MnSO4 + H2O + O2' =>
	[
	    '5 H2O2 + 3 H2SO4 + 2 KMnO4 == 8 H2O + 5 O2 + 1 K2SO4 + 2 MnSO4',
	    '2 H2O + 3 H2SO4 + 2 KMnO4 == 5 H2O2 + 1 K2SO4 + 2 MnSO4',
	    '6 H2SO4 + 4 KMnO4 == 6 H2O + 5 O2 + 2 K2SO4 + 4 MnSO4',
	    '2 H2O2 == 2 H2O + 1 O2',
	    '3 H2SO4 + 2 KMnO4 == 3 H2O2 + 1 O2 + 1 K2SO4 + 2 MnSO4'
        ],
    '2 KMnO4 + 5 H2O2 + H2SO4 --> K2SO4 + MnSO4 + H2O + O2' =>
	[
	    '5 H2O2 + 3 H2SO4 + 2 KMnO4 == 8 H2O + 5 O2 + 1 K2SO4 + 2 MnSO4'
        ],
    'NaOH + HCl + KOH + LiOH, KCl, NaCl + LiCl H2O' =>
	[
          '1 LiCl + 1 NaOH == 1 NaCl + 1 LiOH',
          '1 KCl + 1 NaOH == 1 NaCl + 1 KOH',
          '1 LiCl + 1 KOH == 1 KCl + 1 LiOH',
          '1 HCl + 1 LiOH == 1 LiCl + 1 H2O',
          '1 HCl + 1 NaOH == 1 NaCl + 1 H2O',
          '1 HCl + 1 KOH == 1 KCl + 1 H2O'
        ],
    # Others
    'H2 Ca(CN)2 NaAlF4 FeSO4 MgSiO3 KI H3PO4 PbCrO4 BrCl CF2Cl2 SO2 PbBr2 CrCl3 MgCO3 KAl(OH)4 Fe(SCN)3 PI3 NaSiO3 CaF2 H2O' =>
	[
	    '24 BrCl + 6 CF2Cl2 + 6 NaAlF4 + 119 H2 + 2 H3PO4 + 6 KI + 6 MgSiO3 + 18 Ca(CN)2 + 12 PbCrO4 + 12 FeSO4 + 24 SO2 == 12 PbBr2 + 12 CrCl3 + 18 CaF2 + 110 H2O + 6 KAl(OH)4 + 6 MgCO3 + 6 NaSiO3 + 2 PI3 + 12 Fe(SCN)3'
        ],

    }
}
