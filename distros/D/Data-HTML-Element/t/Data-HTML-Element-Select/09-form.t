use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->form;
is($ret, undef, 'Get form id (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'form' => 'foo',
);
$ret = $obj->form;
is($ret, 'foo', 'Get form id (foo).');
