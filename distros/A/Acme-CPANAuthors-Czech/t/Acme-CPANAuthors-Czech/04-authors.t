use strict;
use utf8;
use warnings;

use Acme::CPANAuthors::Czech;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my %ret = Acme::CPANAuthors::Czech->authors;
my %right_ret = (
	'ATG' => 'Ondřej Vostal',
	'BULB' => 'Jan Hudec',
	'CHOROBA' => 'E. Choroba',
	'CONTYK' => 'Petr Šabata',
	'DANIELR' => 'Roman Daniel',
	'DANPEDER' => 'Daniel Peder',
	'DOUGLISH' => 'Dalibor Hořínek',
	'DPOKORNY' => 'Dan Pokorny',
	'HIHIK' => 'Jiří Václavík',
	'HOLCAPEK' => 'Jan Holčapek',
	'HPA' => 'Petr Vraník',
	'JANPAZ' => 'Jan Pazdziora',
	'JANPOM' => 'Jan Pomikálek',
	'JENDA' => 'Jan Krynický',
	'JIRA' => 'Jiří Pavlovský',
	'JSPICAK' => 'Jakub Špičák',
	'KLE' => 'Petr Kletečka',
	'KOLCON' => 'Luboš Kolouch',
	'MAJLIS' => 'Martin Majlis',
	'MICHALS' => 'Michal Sedlák',
	'MIK' => 'Karel Miko',
	'MILSO' => 'Milan Šorm',
	'MJFO' => 'Michal Jurosz',
	'PAJAS' => 'Petr Pajas',
	'PAJOUT' => 'Jan Poslušný',
	'PASKY' => 'Petr Baudiš',
	'PCIMPRICH' => 'Petr Cimprich',
	'PEK' => 'Petr Kletečka',
	'PETRIS' => 'Petr Malát',
	'POPEL' => 'Martin Popel',
	'PKUBANEK' => 'Petr Kubánek',
	'PSME' => 'Petr Šmejkal',
	'RADIUSCZ' => 'Radek Šiman',
	'RUR' => 'Rudolf Rosa',
	'RVASICEK' => 'Roman Vašíček',
	'SARFY' => 'Martin Šárfy',
	'SEIDLJAN' => 'Jan Seidl',
	'SKIM' => 'Michal Josef Špaček',
	'SMRZ' => 'Otakar Smrž',
	'STRAKA' => 'Milan Straka',
	'TKR' => 'Tomáš Kraut',
	'TPODER' => 'Tomáš Podermański',
	'TRIPIE' => 'Tomáš Stýblo',
	'TYNOVSKY' => 'Miroslav Týnovský',
	'VARISD' => 'Dušan Variš',
	'VASEKD' => 'Václav Dovrtěl',
	'YENYA' => 'Jan "Yenya" Kasprzak',
	'ZABA' => 'Zdeněk Žabokrtský',
	'ZEMAN' => 'Dan Zeman',
	'ZOUL' => 'Tomáš Znamenáček',
);
is_deeply(
	\%ret,
	\%right_ret,
	'Czech CPAN authors.',
);
