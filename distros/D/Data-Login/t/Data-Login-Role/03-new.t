use strict;
use warnings;

use Data::Login::Role;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
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
isa_ok($obj, 'Data::Login::Role');

# Test.
$obj = Data::Login::Role->new(
	'id' => 777,
	'role' => 'admin',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 12,
		'day' => 31,
	),
);
isa_ok($obj, 'Data::Login::Role');

# Test.
eval {
	Data::Login::Role->new(
		'id' => 'bad',
		'role' => 'admin',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a number (bad).");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'role' is required.\n",
	"Parameter 'role' is required.");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'role' => 'admin',
	);
};
is($EVAL_ERROR, "Parameter 'valid_from' is required.\n",
	"Parameter 'valid_from' is required.");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'role' => 'x' x 200,
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'role' has length greater than '100'.\n",
	"Parameter 'role' has length greater than '100'.");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'role' => 'admin',
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
