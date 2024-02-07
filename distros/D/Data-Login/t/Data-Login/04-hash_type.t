use strict;
use warnings;

use Data::HashType;
use Data::Login;
use Test::More 'tests' => 2;
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
isa_ok($obj->hash_type, 'Data::HashType');
