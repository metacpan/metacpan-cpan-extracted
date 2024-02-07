use strict;
use warnings;

use Data::Login::Role;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Data::Login::Role->new(
	'role' => 'admin',
);
isa_ok($obj, 'Data::Login::Role');

# Test.
$obj = Data::Login::Role->new(
	'active' => 1,
	'id' => 777,
	'role' => 'admin',
);
isa_ok($obj, 'Data::Login::Role');

# Test.
eval {
	Data::Login::Role->new(
		'active' => 'bad',
		'role' => 'admin',
	);
};
is($EVAL_ERROR, "Parameter 'active' must be a bool (0/1).\n",
	"Parameter 'active' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'id' => 'bad',
		'role' => 'admin',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a number.\n",
	"Parameter 'id' must be a number (bad).");
clean();

# Test.
eval {
	Data::Login::Role->new;
};
is($EVAL_ERROR, "Parameter 'role' is required.\n",
	"Parameter 'role' is required.");
clean();

# Test.
eval {
	Data::Login::Role->new(
		'role' => 'x' x 200,
	);
};
is($EVAL_ERROR, "Parameter 'role' has length greater than '100'.\n",
	"Parameter 'role' has length greater than '100'.");
clean();
