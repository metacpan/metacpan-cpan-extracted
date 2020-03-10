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
	'PALI' => 'Pavol Rohár',
);
is_deeply(
	\%ret,
	\%right_ret,
	'Slovak CPAN authors.',
);
