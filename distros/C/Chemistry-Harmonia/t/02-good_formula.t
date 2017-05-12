use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test good_formula() #####

my $dt = &datest;

for my $abracadabra ( keys %$dt ){
    is_deeply( [ sort @{ good_formula( $abracadabra ) } ],
		[ sort @{ $dt->{$abracadabra} }], "good formula test '$abracadabra'" );
}

$dt = { 'h20' => [ 'H20', 'H2O' ],
	'l1202' => ['Li202', 'Li2O2'],
	'a120' => [ 'Al20', 'Al2O' ],
	'a1203' => [ 'Al203', 'Al2O3' ],
	'Si204' => [ 'Si204', 'SI204', 'Si2O4', 'SI2O4' ],
	};

for my $abracadabra ( keys %$dt ){
    is_deeply( [ sort @{ good_formula( $abracadabra, { 'zero2oxi' => 1 } ) } ],
		[ sort @{ $dt->{$abracadabra} }], "good formula option 'zero2oxi'" );
}

exit;

sub datest{
    return {
	'H04' => [ 'Ho4', 'HO4' ],
	'H3P04' => [ 'H3Po4', 'H3PO4' ],
	'H2C03' => [ 'H2Co3', 'H2CO3' ],
	'HN03' => [ 'HNo3', 'HNO3' ],
	'H2SO4.' => [ 'H2SO4' ],
	'NACL' => [ 'NaCl' ],
	'ALCL3' => [ 'AlCl3' ],
	'Si204' => [ 'Si204', 'SI204' ],
	'o$' => [ 'Os', 'OS' ],
	'qsQsQ' =>  [ 'SOsO', 'SOSO' ],
	'aqhqmqrqsq' => [ 'AgHgMgRgSg' ],
	'a1203' => [ 'Al203' ],
	'1' => [ 'I' ],
	't|' => [ 'Tl' ],
	'l1' => [ 'Li' ],
	'b!' => [ 'BI', 'Bi' ],
	'!2' => [ 'I2' ],
	'|2' => [ 'I2' ],
	'12' => [ 'I2' ],
	'102' => [ 'IO2' ],
	'a1' => [ 'Al' ],
	'c1' => [ 'Cl' ],
	'Co' => [ 'Co' ],
	'Cc' => [ 'CC' ],
	'co' => [ 'CO','Co' ],
	'CO2' => [ 'CO2' ],
	'Co2' => [ 'Co2', 'CO2' ],
	'[{(na)}]' => [ 'Na' ],
	'0.3al2o3*1.5sio2' => [ '{Al2O3}{SIO2}5', '{Al2O3}{SiO2}5' ],
	'00O02' => [ 'OOOO2' ],
	'h20' => [ 'H20' ],
	'{[[([[CaO]])*((SiO2))]]}' => [ '{([[CaO]])}{((SiO2))}' ],
	'Irj(){}[]' => [ 'IrI' ],
	'..,,..mg0,,,,.*si0...s..,..' => [ '{MgO}{SIOS}', '{MgO}{SiOS}' ],
	'al2(so4)3*10h20' => [ '{Al2(SO4)3}{H20}10' ],
	'{[cr(c0(nh2)2)6]4[cr(cn)6{df}]3}' => [
		'[Cr(CO(NH2)2)6]4[Cr(CN)6{DF}]3',
		'[Cr(Co(NH2)2)6]4[Cr(CN)6{DF}]3',
		'[Cr(CO(NH2)2)6]4[Cr(Cn)6{DF}]3',
		'[Cr(Co(NH2)2)6]4[Cr(Cn)6{DF}]3'
		],
	'ggg[crr(cog(nhr2)2)6]4[qcr(rcn)5j]3rrrrr' => [
		'[Cr(CO(NH2)2)6]4[Cr(CN)5I]3',
		'[Cr(Co(NH2)2)6]4[Cr(CN)5I]3'
		],
'gggrrrgggknalllisrmgfeusoseurrrlllrrr' => [
		'RgKNAlLiSrMgFEuSOSEuLr',
		'RgKNAlLiSrMgFEuSOSeULr',
		'RgKNAlLiSrMgFEuSOsEuLr',
		'RgKNAlLiSrMgFeUSOSEuLr',
		'RgKNAlLiSrMgFeUSOSeULr',
		'RgKNAlLiSrMgFeUSOsEuLr'
		],
'genAal(so4)2cO2j(FfeueuCCCCoco)' => [
		'GeNaAl(SO4)2CO2I(FFEuEuCCCCoCO)',
		'GeNaAl(SO4)2CO2I(FFEuEuCCCCoCo)',
		'GeNaAl(SO4)2CO2I(FFeUEuCCCCoCO)',
		'GeNaAl(SO4)2CO2I(FFeUEuCCCCoCo)',
		'GeNaAl(SO4)2CO2I(FFEuEuCCCCOCO)',
		'GeNaAl(SO4)2CO2I(FFeUEuCCCCOCO)',
		'GeNaAl(SO4)2CO2I(FFEuEuCCCCOCo)',
		'GeNaAl(SO4)2CO2I(FFeUEuCCCCOCo)',
		],
'knalisrmgfeusoseu' => [
		'KNAlISrMgFEuSOSEu',
		'KNaLiSrMgFEuSOSEu',
		'KNAlISrMgFEuSOSeU',
		'KNaLiSrMgFEuSOSeU',
		'KNAlISrMgFEuSOsEu',
		'KNaLiSrMgFEuSOsEu',
		'KNAlISrMgFeUSOSEu',
		'KNaLiSrMgFeUSOSEu',
		'KNAlISrMgFeUSOSeU',
		'KNaLiSrMgFeUSOSeU',
		'KNAlISrMgFeUSOsEu',
		'KNaLiSrMgFeUSOsEu',
		],
'naliseusndyptc' => [
		'NAlISEuSNDYPTC',
		'NAlISEuSNDYPTc',
		'NAlISEuSNDYPtC',
		'NAlISEuSNDyPTC',
		'NAlISEuSNDyPTc',
		'NAlISEuSNDyPtC',
		'NAlISEuSNdYPTC',
		'NAlISEuSNdYPTc',
		'NAlISEuSNdYPtC',
		'NAlISEuSnDYPTC',
		'NAlISEuSnDYPTc',
		'NAlISEuSnDYPtC',
		'NAlISEuSnDyPTC',
		'NAlISEuSnDyPTc',
		'NAlISEuSnDyPtC',
		'NAlISeUSNDYPTC',
		'NAlISeUSNDYPTc',
		'NAlISeUSNDYPtC',
		'NAlISeUSNDyPTC',
		'NAlISeUSNDyPTc',
		'NAlISeUSNDyPtC',
		'NAlISeUSNdYPTC',
		'NAlISeUSNdYPTc',
		'NAlISeUSNdYPtC',
		'NAlISeUSnDYPTC',
		'NAlISeUSnDYPTc',
		'NAlISeUSnDYPtC',
		'NAlISeUSnDyPTC',
		'NAlISeUSnDyPTc',
		'NAlISeUSnDyPtC',
		'NaLiSEuSNDYPTC',
		'NaLiSEuSNDYPTc',
		'NaLiSEuSNDYPtC',
		'NaLiSEuSNDyPTC',
		'NaLiSEuSNDyPTc',
		'NaLiSEuSNDyPtC',
		'NaLiSEuSNdYPTC',
		'NaLiSEuSNdYPTc',
		'NaLiSEuSNdYPtC',
		'NaLiSEuSnDYPTC',
		'NaLiSEuSnDYPTc',
		'NaLiSEuSnDYPtC',
		'NaLiSEuSnDyPTC',
		'NaLiSEuSnDyPTc',
		'NaLiSEuSnDyPtC',
		'NaLiSeUSNDYPTC',
		'NaLiSeUSNDYPTc',
		'NaLiSeUSNDYPtC',
		'NaLiSeUSNDyPTC',
		'NaLiSeUSNDyPTc',
		'NaLiSeUSNDyPtC',
		'NaLiSeUSNdYPTC',
		'NaLiSeUSNdYPTc',
		'NaLiSeUSNdYPtC',
		'NaLiSeUSnDYPTC',
		'NaLiSeUSnDYPTc',
		'NaLiSeUSnDYPtC',
		'NaLiSeUSnDyPTC',
		'NaLiSeUSnDyPTc',
		'NaLiSeUSnDyPtC'
		],
	}
}
