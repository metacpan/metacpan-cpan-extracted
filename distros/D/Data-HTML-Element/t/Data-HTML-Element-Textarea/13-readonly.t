use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->readonly;
is($ret, 0, 'Get readonly flag (default = 0).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'readonly' => 1,
);
$ret = $obj->readonly;
is($ret, 1, 'Get readonly flag (1).');
