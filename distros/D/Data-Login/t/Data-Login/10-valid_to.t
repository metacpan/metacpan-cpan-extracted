use strict;
use warnings;

use Data::HashType;
use Data::Login;
use DateTime;
use Test::More 'tests' => 4;
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
is($obj->valid_to, undef, 'Get valid to (undef - default).');

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
is($obj->valid_to->ymd, '2024-12-31', 'Get valid to in ymd format (2024-12-31).');
