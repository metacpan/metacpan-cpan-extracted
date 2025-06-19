use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_cataloging_source);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'c',
};
my $ret = check_cataloging_source($self, 'key');
is($ret, undef, 'Right cataloging source is present (c).');

# Test.
$self = {
	'key' => ' ',
};
$ret = check_cataloging_source($self, 'key');
is($ret, undef, 'Right cataloging source is present ( ).');

# Test.
$self = {
	'key' => '|',
};
$ret = check_cataloging_source($self, 'key');
is($ret, undef, 'Right cataloging source is present (|).');

# Test.
$self = {};
eval {
	check_cataloging_source($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_cataloging_source($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_cataloging_source($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'e',
};
eval {
	check_cataloging_source($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (e).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_cataloging_source($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
