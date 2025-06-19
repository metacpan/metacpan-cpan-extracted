use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_continuing_resource_entry_convention);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '0',
};
my $ret = check_continuing_resource_entry_convention($self, 'key');
is($ret, undef, 'Right continuing resource entry convention is present (0).');

# Test.
$self = {
	'key' => '|',
};
$ret = check_continuing_resource_entry_convention($self, 'key');
is($ret, undef, 'Right continuing resource entry convention is present (|).');

# Test.
$self = {};
eval {
	check_continuing_resource_entry_convention($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_continuing_resource_entry_convention($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_continuing_resource_entry_convention($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => '9',
};
eval {
	check_continuing_resource_entry_convention($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (9).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_continuing_resource_entry_convention($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
