use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_map_special_format);
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'ej',
};
my $ret = check_map_special_format($self, 'key');
is($ret, undef, 'Right relief is present (ej).');

# Test.
$self = {
	'key' => '  ',
};
$ret = check_map_special_format($self, 'key');
is($ret, undef, 'Right relief is present (  ).');

# Test.
$self = {
	'key' => '||',
};
$ret = check_map_special_format($self, 'key');
is($ret, undef, 'Right relief is present (||).');

# Test.
$self = {};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'e|',
};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with pipe character.\n",
	"Parameter 'key' has value with pipe character (e|).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'ew',
};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contains bad special format characteristics character.\n",
	"Parameter 'key' contain bad special format characteristics character (ew).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_map_special_format($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
