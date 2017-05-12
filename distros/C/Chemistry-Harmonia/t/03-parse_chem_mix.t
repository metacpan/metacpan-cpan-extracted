use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok('Chemistry::Harmonia') };
use Chemistry::Harmonia qw(:all);

##### Test parse_chem_mix() #####

my $dt = &datest;
my $ot = &oxitest;

for my $i (0,1){
    my $p = $i ? 'zero2oxi' : '';

    for my $mix ( keys %$dt ){
	my %k = $i ? ($p => 1) : ( );
	
	is_deeply( [ @{ parse_chem_mix($mix, \%k) }, \%k ],
	    $dt->{$mix}, "$p parse test '$mix'" );
    }

    for my $mix ( keys %$ot ){
	my %k = $i ? ($p => 1) : ( );
	is_deeply( [ @{ parse_chem_mix($mix, \%k) }, \%k ],
		$ot->{ $mix }[$i],
		"$p parse test '$mix'" );
    }
}

for my $mix ('2Al = 0 0Al2O3', '2Al = 0 Al2O3', '1 FE+' ){
    is( parse_chem_mix( $mix ), undef, "parse test '$mix'" );
}

exit;


sub datest{
    return {
    '1 O2 +++;;;++,,, 2 ;; H2 = 2 +++ H2O' => [ ['O2', 'H2'], ['H2O'], {'O2' => 1, 'H2' => 2, 'H2O' => 2} ],
    '2Al 1 02 Ca Al2O3' => [ ['Al', 'O2', 'Ca'], ['Al2O3'], {'Al' => 2, 'O2' => 1} ],
    '2Al 102 Ca Al2O3' => [ ['Al', 'Ca'], ['Al2O3'], {'Al' => 2, 'Ca' => 102} ],
    '2Al 1 02 4O2 = 1 0Al2O3' => [ ['Al', 'O2'], ['OAl2O3'], {'Al' => 2, 'O2' => 4, 'OAl2O3' => 1} ],
    '2Al = 00 Al2O3' => [ ['Al'], ['O0', 'Al2O3'], {'Al' => 2} ],
    '2Al O 2 = Al2O3' => [ ['Al', 'O2'], ['Al2O3'], {'Al' => 2} ],
    '2Al O = ' => [ ['Al', 'O'], ['='], {'Al' => 2} ],
    ' = 2Al O' => [ ['=','Al'], ['O'], {'Al' => 2} ],
    '0Al = O2 Al2O3' => [ ['O2'], ['Al2O3'], {} ],
    '2Al 1 2 3 4 Ca 5 6 Al2O3 7 8 9' => [ ['Al', 'Ca'], ['Al2O3'], {'Al2O3' => 56, 'Al' => 2, 'Ca' => 1234} ],
    '2Al 1 2 3 4 Ca 5 6 Al2O3' => [ ['Al', 'Ca'], ['Al2O3'], {'Al2O3' => 56, 'Al' => 2, 'Ca' => 1234} ],
    '2Al 1 2 3 4 Ca 5 6 = Al2O3' => [ ['Al', 'Ca56'], ['Al2O3'], {'Al' => 2, 'Ca56' => 1234} ],
    '2Al 1 2 3 4 Ca 5 6 = Al2O3 CaO 9' => [ ['Al', 'Ca56'], ['Al2O3', 'CaO'], {'Al' => 2, 'Ca56' => 1234} ],
    '(SCN) 2 + H2O ' => [ ['(SCN)2'], ['H2O'], {} ],
    'Al O + 2 = Al2O3' => [ ['Al', 'O'], ['Al2O3'], {'Al2O3' => 2} ],
    'Cr( OH )  3 + NaOH = Na3[ Cr( OH )  6  ]' => [ ['Cr(OH)3', 'NaOH'], ['Na3[Cr(OH)6]'], {} ],
    }
}

sub oxitest{
    return {
    '2Al O O O O  = 0 Al2O3 1 0' => [
		[ ['Al'], ['O'], {'Al' => 2, 'O' => 1} ],
		[ ['Al', 'O'], ['Al2O3'], {'Al' => 2, 'O' => 1} ]
		],
    '2Al = 0 Al2O3 0' => [
		[ ['Al'], ['O'], {'Al' => 2} ],
		[ ['Al'], ['O', 'Al2O3'], {'Al' => 2} ]
		],
    'Al O2 = 0 Al2O3' => [
		[ ['Al'], ['O2'], {} ],
		[ ['Al', 'O2'], ['O', 'Al2O3'], {} ]
		],
    }
}
