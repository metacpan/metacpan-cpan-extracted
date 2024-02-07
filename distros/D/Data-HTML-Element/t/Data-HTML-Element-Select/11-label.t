use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->label;
is($ret, undef, 'Get label (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'label' => 'foo',
);
$ret = $obj->label;
is($ret, 'foo', 'Get label (foo).');
