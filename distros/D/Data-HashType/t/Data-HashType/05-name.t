use strict;
use warnings;

use Data::HashType;
use DateTime;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'name' => 'SHA1',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is($obj->name, 'SHA1', 'Get name (SHA1).');
