use strict;
use warnings;

use Data::HashType;
use Data::Login;
use DateTime;
use Test::More 'tests' => 2;
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
is($obj->password_hash, 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	'Get password hash (aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f).');
