use strict;
use warnings;

use Data::HTML::Element::Utils qw(check_data_type);
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {};
my $ret = check_data_type($self);
is($ret, undef, 'Check of data type is ok (plain = default).');
is($self->{'data_type'}, 'plain', 'Default value (plain).');

# Test.
$self = {
	'data_type' => 'plain',
};
$ret = check_data_type($self);
is($ret, undef, 'Check of data type is ok (plain).');

# Test.
$self = {
	'data_type' => 'tags',
};
$ret = check_data_type($self);
is($ret, undef, 'Check of data type is ok (tags).');

# Test.
$self = {
	'data_type' => 'cb',
};
$ret = check_data_type($self);
is($ret, undef, 'Check of data type is ok (cb).');

# Test.
$self = {
	'data_type' => 'bad',
};
eval {
	check_data_type($self);
};
is($EVAL_ERROR, "Parameter 'data_type' has bad value.\n",
	"Parameter 'data_type' has bad value (bad).");
clean();
