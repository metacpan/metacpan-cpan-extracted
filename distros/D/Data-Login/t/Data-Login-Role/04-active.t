use strict;
use warnings;

use Data::Login::Role;
use DateTime;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is($obj->active, 1, 'Get active (1 - default).');

# Test.
$obj = Data::Login::Role->new(
	'active' => 1,
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is($obj->active, 1, 'Get active (1).');

# Test.
$obj = Data::Login::Role->new(
	'active' => 0,
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is($obj->active, 0, 'Get active (0).');
