use strict;
use warnings;

use Data::HashType;
use DateTime;
use Test::More 'tests' => 3;
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
isa_ok($obj->valid_from, 'DateTime');
is($obj->valid_from->ymd, '2024-01-01', 'Get valid from in ymd format (2024-01-01).');
