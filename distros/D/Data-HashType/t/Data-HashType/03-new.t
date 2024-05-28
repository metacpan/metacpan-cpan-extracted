use strict;
use warnings;

use Data::HashType;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'name' => 'SHA1',
	'valid_from' => DateTime->new(
		'year' => 2024,
		'month' => 1,
		'day' => 1,
	),
);
isa_ok($obj, 'Data::HashType');

# Test.
eval {
	Data::HashType->new(
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'name' is required.\n",
	"Parameter 'name' is required.");
clean();

# Test.
eval {
	Data::HashType->new(
		'name' => 'x' x 60,
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'name' has length greater than '50'.\n",
	"Parameter 'name' has length greater than '50'.");
clean();

# Test.
eval {
	Data::HashType->new(
		'id' => 'bad',
		'name' => 'SHA1',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a natural number.\n",
	"Parameter 'id' must be a natural number (bad).");
clean();

# Test.
eval {
	Data::HashType->new(
		'name' => 'SHA1',
	);
};
is($EVAL_ERROR, "Parameter 'valid_from' is required.\n",
	"Parameter 'valid_from' is required.");
clean();

# Test.
eval {
	Data::HashType->new(
		'name' => 'SHA1',
		'valid_from' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'valid_from' must be a 'DateTime' object.\n",
	"Parameter 'valid_from' must be a 'DateTime' object (bad).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Data::HashType->new(
		'name' => 'SHA1',
		'valid_from' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'valid_from' must be a 'DateTime' object.\n",
	"Parameter 'valid_from' must be a 'DateTime' object (bad object).");
clean();

# Test.
eval {
	Data::HashType->new(
		'name' => 'SHA1',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
		'valid_to' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'valid_to' must be a 'DateTime' object.\n",
	"Parameter 'valid_to' must be a 'DateTime' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::HashType->new(
		'name' => 'SHA1',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
		'valid_to' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'valid_to' must be a 'DateTime' object.\n",
	"Parameter 'valid_to' must be a 'DateTime' object (bad object).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::HashType->new(
		'name' => 'SHA1',
		'valid_from' => DateTime->new(
			'year' => 2024,
			'month' => 1,
			'day' => 1,
		),
		'valid_to' => DateTime->new(
			'year' => 2023,
			'month' => 12,
			'day' => 31,
		),
	);
};
is($EVAL_ERROR, "Parameter 'valid_to' must be older than 'valid_from' parameter.\n",
	"Parameter 'valid_to' must be older than 'valid_from' parameter.");
clean();
