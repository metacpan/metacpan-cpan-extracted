use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {
	'data' => ['foo'],
	'data_type' => 'plain',
};
my $ret = check_data($self);
is($ret, undef, 'Data are ok (plain).');

# Test.
$self = {
	'data' => [['b', 'begin']],
	'data_type' => 'tags',
};
$ret = check_data($self);
is($ret, undef, 'Data are ok (tags).');

# Test.
$self = {
	'data' => [sub {}],
	'data_type' => 'cb',
};
$ret = check_data($self);
is($ret, undef, 'Data are ok (cb).');

# Test.
$self = {
	'data' => 'foo',
};
eval {
	check_data($self);
};
is($EVAL_ERROR, "Parameter 'data' must be a array.\n",
	"Parameter 'data' must be a array.");
clean();

# Test.
$self = {
	'data' => [\'foo'],
	'data_type' => 'plain',
};
eval {
	check_data($self);
};
is($EVAL_ERROR, "Parameter 'data' in 'plain' mode must contain reference to array with scalars.\n",
	"Parameter 'data' in 'plain' mode must contain reference to array with scalars.");
clean();

# Test.
$self = {
	'data' => ['foo'],
	'data_type' => 'tags',
};
eval {
	check_data($self);
};
is($EVAL_ERROR, "Parameter 'data' in 'tags' mode must contain reference to array ".
	"with references to array with Tags structure.\n",
	"Parameter 'data' in 'tags' mode must contain reference to array with ".
	"references to array with Tags structure.");
clean();

# Test.
$self = {
	'data' => ['foo'],
	'data_type' => 'cb',
};
eval {
	check_data($self);
};
is($EVAL_ERROR, "Parameter 'data' in 'cb' mode must contain reference to code with callback.\n",
	"Parameter 'data' in 'cb' mode must contain reference to code with callback.");
clean();
