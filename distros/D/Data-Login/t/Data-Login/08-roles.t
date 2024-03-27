use strict;
use warnings;

use Data::HashType;
use Data::Login;
use Data::Login::Role;
use DateTime;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'name' => 'sha256',
		'valid_from' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => 2024,
		),
	),
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
is_deeply(
	$obj->roles,
	[],
	'Get default roles (no roles).',
);

# Test.
$obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'name' => 'sha256',
		'valid_from' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => 2024,
		),
	),
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	'roles' => [
		Data::Login::Role->new(
			'id' => 1,
			'role' => 'admin',
			'valid_from' => DateTime->new(
				'year' => 2024,
				'month' => 2,
				'day' => 1,
			),
		),
	],
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
isa_ok($obj->roles->[0], 'Data::Login::Role');
