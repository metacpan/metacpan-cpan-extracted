use strict;
use warnings;

use Data::HashType;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::HashType->new(
	'active' => 1,
	'name' => 'SHA1',
);
isa_ok($obj, 'Data::HashType');

# Test.
eval {
	Data::HashType->new(
		'active' => 1,
	);
};
is($EVAL_ERROR, "Parameter 'name' is required.\n",
	"Parameter 'name' is required.");
clean();

# Test.
eval {
	Data::HashType->new(
		'name' => 'x' x 60,
	);
};
is($EVAL_ERROR, "Parameter 'name' has length greater than '50'.\n",
	"Parameter 'name' has length greater than '50'.");
clean();

# Test.
eval {
	Data::HashType->new(
		'active' => 'bad',
		'name' => 'SHA1',
	);
};
is($EVAL_ERROR, "Parameter 'active' must be a bool (0/1).\n",
	"Parameter 'active' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HashType->new(
		'id' => 'bad',
		'name' => 'SHA1',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a number.\n",
	"Parameter 'id' must be a number.");
clean();
