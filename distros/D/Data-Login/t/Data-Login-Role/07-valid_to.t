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
is($obj->valid_to, undef, 'Get valid to (undef - default).');

# Test.
$obj = Data::Login::Role->new(
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
	'valid_to' => DateTime->new(
		'year' => 2024,
		'month' => 12,
		'day' => 31,
	),
);
isa_ok($obj->valid_to, 'DateTime');
is($obj->valid_to->ymd, '2024-12-31', 'Get valid to (2024-12-31).');
