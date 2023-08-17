use strict;
use utf8;
use warnings;

use Acme::CPANAuthors::Slovak;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my %ret = Acme::CPANAuthors::Slovak->authors;
my %right_ret = (
	'BARNEY' => 'Branislav Zahradník',
	'JKUTEJ' => 'Jozef Kutej',
	'KOZO' => "Ján 'Kozo' Vajda",
	'LKUNDRAK' => 'Lubomir Rintel',
	'PALI' => 'Pavol Rohár',
	'SAMSK' => 'Samuel Behan',
);
is_deeply(
	\%ret,
	\%right_ret,
	'Slovak CPAN authors.',
);
