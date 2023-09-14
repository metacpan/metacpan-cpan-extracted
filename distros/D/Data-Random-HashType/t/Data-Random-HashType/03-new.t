use strict;
use warnings;

use Data::Random::HashType;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::Random::HashType->new;
isa_ok($obj, 'Data::Random::HashType');

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
