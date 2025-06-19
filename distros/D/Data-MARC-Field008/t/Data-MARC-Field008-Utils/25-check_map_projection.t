use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_map_projection);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'aa',
};
my $ret = check_map_projection($self, 'key');
is($ret, undef, 'Right projection is present (aa).');

# Test.
$self = {
	'key' => '  ',
};
$ret = check_map_projection($self, 'key');
is($ret, undef, 'Right projection is present (  ).');

# Test.
$self = {
	'key' => '||',
};
$ret = check_map_projection($self, 'key');
is($ret, undef, 'Right projection is present (||).');

# Test.
$self = {};
eval {
	check_map_projection($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_map_projection($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_map_projection($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'a1',
};
eval {
	check_map_projection($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (a1).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_map_projection($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
