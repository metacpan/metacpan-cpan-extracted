use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->name;
is($ret, undef, 'Get name (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'name' => 'foo',
);
$ret = $obj->name;
is($ret, 'foo', 'Get name (foo).');
