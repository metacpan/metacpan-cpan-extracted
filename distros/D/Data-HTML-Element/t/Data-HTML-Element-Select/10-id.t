use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->id;
is($ret, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'id' => 'foo',
);
$ret = $obj->id;
is($ret, 'foo', 'Get id (foo).');
