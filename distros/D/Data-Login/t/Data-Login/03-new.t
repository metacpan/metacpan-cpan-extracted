use strict;
use warnings;

use Data::HashType;
use Data::Login;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
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
isa_ok($obj, 'Data::Login');

# Test.
eval {
	Data::Login->new(
		'login_name' => 'skim',
		# foobar
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'hash_type' is required.\n",
	"Parameter 'hash_type' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'name' => 'sha256',
			'valid_from' => DateTime->new(
				'day' => 1,
				'month' => 1,
				'year' => 2024,
			),
		),
		'id' => 'bad',
		'login_name' => 'skim',
		# foobar
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a natural number.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'name' => 'sha256',
			'valid_from' => DateTime->new(
				'day' => 1,
				'month' => 1,
				'year' => 2024,
			),
		),
		# foobar
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'login_name' is required.\n",
	"Parameter 'login_name' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'name' => 'sha256',
			'valid_from' => DateTime->new(
				'day' => 1,
				'month' => 1,
				'year' => 2024,
			),
		),
		'login_name' => 'skim',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'password_hash' is required.\n",
	"Parameter 'password_hash' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'name' => 'sha256',
			'valid_from' => DateTime->new(
				'day' => 1,
				'month' => 1,
				'year' => 2024,
			),
		),
		'login_name' => 'skim',
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	);
};
is($EVAL_ERROR, "Parameter 'valid_from' is required.\n",
	"Parameter 'valid_from' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'name' => 'sha256',
			'valid_from' => DateTime->new(
				'day' => 1,
				'month' => 1,
				'year' => 2024,
			),
		),
		'login_name' => 'skim',
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
		'valid_from' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => 2024,
		),
		'valid_to' => DateTime->new(
			'day' => 1,
			'month' => 1,
			'year' => 2023,
		),
	);
};
is($EVAL_ERROR, "Parameter 'valid_to' must be older than 'valid_from' parameter.\n",
	"Parameter 'valid_to' must be older than 'valid_from' parameter.");
clean();
