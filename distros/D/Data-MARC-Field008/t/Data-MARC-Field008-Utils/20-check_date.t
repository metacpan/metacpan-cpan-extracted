use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_date);
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '1999',
};
my $ret = check_date($self, 'key');
is($ret, undef, 'Right date is present (1999).');

# Test.
$self = {
	'key' => '    ',
};
$ret = check_date($self, 'key');
is($ret, undef, 'Right date is present (    ).');

# Test.
$self = {
	'key' => '||||',
};
$ret = check_date($self, 'key');
is($ret, undef, 'Right date is present (||||).');

# Test.
$self = {
	'key' => '18uu',
};
$ret = check_date($self, 'key');
is($ret, undef, 'Right date is present (18uu).');

# Test.
$self = {};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => '199 ',
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with space character.\n",
	"Parameter 'key' has value with space character (199 ).");
clean();

# Test.
$self = {
	'key' => '199|',
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with pipe character.\n",
	"Parameter 'key' has value with pipe character (199|).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'foo1',
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (foo1).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_date($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
