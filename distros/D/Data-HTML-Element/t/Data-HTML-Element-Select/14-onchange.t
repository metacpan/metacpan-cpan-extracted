use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->onchange;
is($ret, undef, 'Get onchange (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'onchange' => "alert('Hello, world';)",
);
$ret = $obj->onchange;
is($ret, "alert('Hello, world';)", "Get onchange (alert('Hello, world');).");
