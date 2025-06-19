use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::MARC::Field008::Utils qw(check_book_nature_of_content);
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'ab  ',
};
my $ret = check_book_nature_of_content($self, 'key');
is($ret, undef, 'Right book nature of content is present (ab  ).');

# Test.
$self = {
	'key' => '    ',
};
$ret = check_book_nature_of_content($self, 'key');
is($ret, undef, 'Right book nature of content is present (    ).');

# Test.
$self = {
	'key' => '||||',
};
$ret = check_book_nature_of_content($self, 'key');
is($ret, undef, 'Right book nature of content is present (||||).');

# Test.
$self = {};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (key not exists).");
clean();

# Test.
$self = {
	'key' => undef,
};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' is required.\n",
	"Parameter 'key' is required (undef).");
clean();

# Test.
$self = {
	'key' => 'a|||',
};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has value with pipe character.\n",
	"Parameter 'key' has value with pipe character (a|||).");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' length is bad.\n",
	"Parameter 'key' length is bad (foo).");
clean();

# Test.
$self = {
	'key' => 'foo1',
};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad value.\n",
	"Parameter 'key' has bad value (foo1).");
clean();

# Test.
$self = {
	'key' => [],
};
eval {
	check_book_nature_of_content($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a scalar value.\n",
	"Parameter 'key' must be a scalar value ([]).");
clean();
