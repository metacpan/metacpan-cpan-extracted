use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_visual_material_running_time);
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '000',
};
my $ret = check_visual_material_running_time($self, 'key');
is($ret, undef, 'Right visual material running time is present (000).');

# Test.
$self = {
	'key' => '|||',
};
$ret = check_visual_material_running_time($self, 'key');
is($ret, undef, 'Right visual material running time is present (|||).');

# Test.
$self = {
	'key' => 'nnn',
};
$ret = check_visual_material_running_time($self, 'key');
is($ret, undef, 'Right visual material running time is present (nnn).');

# Test.
$self = {
	'key' => '123',
};
$ret = check_visual_material_running_time($self, 'key');
is($ret, undef, 'Right visual material running time is present (123).');

# Test.
$self = {
	'key' => '---',
};
$ret = check_visual_material_running_time($self, 'key');
is($ret, undef, 'Right visual material running time is present (---).');

# Test.
$self = {};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo1',
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => '11-',
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with dash character.\n",
	"Parameter 'key' has value with dash character (11-).");
clean();

# Test.
$self = {
	'key' => '11|',
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with pipe character.\n",
	"Parameter 'key' has value with pipe character (11|).");
clean();

# Test.
$self = {
	'key' => '11n',
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with 'n' character.\n",
	"Parameter 'key' has value with 'n' character (11n).");
clean();

# Test.
$self = {
	'key' => '11a',
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contains bad visual material running time.\n",
	"Parameter 'key' contains bad visual material running time (11a).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_visual_material_running_time($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
