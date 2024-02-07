use strict;
use warnings;

use Data::HashType;
use Data::Login;
use Data::Login::Role;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'active' => 1,
		'name' => 'sha256',
	),
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
);
is_deeply(
	$obj->roles,
	[],
	'Get default roles (no roles).',
);

# Test.
$obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'active' => 1,
		'name' => 'sha256',
	),
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	'roles' => [
		Data::Login::Role->new(
			'id' => 1,
			'role' => 'admin',
		),
	],
);
isa_ok($obj->roles->[0], 'Data::Login::Role');
