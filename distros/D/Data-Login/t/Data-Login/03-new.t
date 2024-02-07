use strict;
use warnings;

use Data::HashType;
use Data::Login;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
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
isa_ok($obj, 'Data::Login');

# Test.
eval {
	Data::Login->new(
		'login_name' => 'skim',
		# foobar
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	);
};
is($EVAL_ERROR, "Parameter 'hash_type' is required.\n",
	"Parameter 'hash_type' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'active' => 1,
			'name' => 'sha256',
		),
		# foobar
		'password_hash' => 'aec070645fe53ee3b3763059376134f058cc337247c978add178b6ccdfb0019f',
	);
};
is($EVAL_ERROR, "Parameter 'login_name' is required.\n",
	"Parameter 'login_name' is required.");
clean();

# Test.
eval {
	Data::Login->new(
		'hash_type' => Data::HashType->new(
			'active' => 1,
			'name' => 'sha256',
		),
		'login_name' => 'skim',
	);
};
is($EVAL_ERROR, "Parameter 'password_hash' is required.\n",
	"Parameter 'password_hash' is required.");
clean();
