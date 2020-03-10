use strict;
use warnings;

use Acme::CPANAuthors;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Acme::CPANAuthors->new('Czech');
my @ret = $obj->id;
my @right_ret = ('CHOROBA', 'DANIELR', 'DANPEDER', 'DOUGLISH', 'HIHIK',
	'HOLCAPEK', 'HPA', 'JANPAZ', 'JANPOM', 'JENDA', 'JIRA', 'JSPICAK', 'KLE',
	'KOLCON', 'MAJLIS', 'MICHALS', 'MILSO', 'MJFO', 'PAJAS', 'PASKY', 'PEK',
	'POPEL', 'PSME', 'RUR', 'RVASICEK', 'SARFY', 'SEIDLJAN', 'SKIM', 'SMRZ',
	'STRAKA', 'TKR', 'TRIPIE', 'TYNOVSKY', 'VARISD', 'VASEKD', 'YENYA',
	'ZABA', 'ZEMAN', 'ZOUL');
is_deeply(\@ret, \@right_ret, 'CPAN authors ids.');
