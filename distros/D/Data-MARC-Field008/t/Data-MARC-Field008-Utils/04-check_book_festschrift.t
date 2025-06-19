use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_book_festschrift);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => '0',
};
my $ret = check_book_festschrift($self, 'key');
is($ret, undef, 'Right book festschrift is present (0).');

# Test.
$self = {
	'key' => '|',
};
$ret = check_book_festschrift($self, 'key');
is($ret, undef, 'Right book festschrift is present (|).');

# Test.
$self = {};
eval {
	check_book_festschrift($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_book_festschrift($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_book_festschrift($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => '2',
};
eval {
	check_book_festschrift($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (2).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_book_festschrift($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
