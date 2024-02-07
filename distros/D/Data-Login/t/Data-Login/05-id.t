use strict;
use warnings;

use Data::HashType;
use Data::Login;
use Test::More 'tests' => 4;
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
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'active' => 1,
		'name' => 'sha256',
	),
	'id' => 777,
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
);
is($obj->id, 777, 'Get id (777).');

# Test.
$obj = Data::Login->new(
	'hash_type' => Data::HashType->new(
		'active' => 1,
		'name' => 'sha256',
	),
	'id' => undef,
	'login_name' => 'skim',
	# foobar
	'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
);
is($obj->id, undef, 'Get id (undef).');
