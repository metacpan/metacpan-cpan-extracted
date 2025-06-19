use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_book_biography);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'a',
};
my $ret = check_book_biography($self, 'key');
is($ret, undef, 'Right book biography are present (a).');

# Test.
$self = {
	'key' => ' ',
};
$ret = check_book_biography($self, 'key');
is($ret, undef, 'Right book biography are present ( ).');

# Test.
$self = {
	'key' => '|',
};
$ret = check_book_biography($self, 'key');
is($ret, undef, 'Right book biography are present (|).');

# Test.
$self = {};
eval {
	check_book_biography($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_book_biography($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_book_biography($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'x',
};
eval {
	check_book_biography($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (x).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_book_biography($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
