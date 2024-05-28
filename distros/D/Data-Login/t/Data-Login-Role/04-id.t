use strict;
use warnings;

use Data::Login::Role;
use DateTime;
use Test::More 'tests' => 3;
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
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Login::Role->new(
	'id' => 10,
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is($obj->id, 10, 'Get id (10).');
