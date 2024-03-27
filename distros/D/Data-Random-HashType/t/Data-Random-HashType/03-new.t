use strict;
use warnings;

use Data::Random::HashType;
use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Data::Random::HashType->new;
isa_ok($obj, 'Data::Random::HashType');

# Test.
eval {
	Data::Random::HashType->new(
		'mode_id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'mode_id' must be a bool (0/1).\n",
	"Parameter 'mode_id' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::Random::HashType->new(
		'num_generated' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'num_generated' is required.\n",
	"Parameter 'num_generated' is required.");
clean();

# Test.
eval {
	Data::Random::HashType->new(
		'num_generated' => -4,
	);
};
is($EVAL_ERROR, "Parameter 'num_generated' must be greater than 1.\n",
	"Parameter 'num_generated' must be greater than 1 (-4).");
clean();

# Test.
eval {
	Data::Random::HashType->new(
		'possible_hash_types' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'possible_hash_types' must be a reference to array.\n",
	"Parameter 'possible_hash_types' must be a reference to array.");
clean();

# Test.
eval {
	Data::Random::HashType->new(
		'possible_hash_types' => [],
	);
};
is($EVAL_ERROR, "Parameter 'possible_hash_types' must contain at least one hash type name.\n",
	"Parameter 'possible_hash_types' must contain at least one hash type name.");
clean();

# Test.
eval {
	Data::Random::HashType->new(
		'dt_start' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'dt_start' is required.\n",
	"Parameter 'dt_start' is required.");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Data::Random::HashType->new(
		'dt_start' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'dt_start' must be a 'DateTime' object.\n",
	"Parameter 'dt_start' must be a 'DateTime' object.");
clean();
