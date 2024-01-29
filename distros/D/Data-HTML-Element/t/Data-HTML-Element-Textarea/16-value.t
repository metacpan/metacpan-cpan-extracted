use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->value;
is($ret, undef, 'Get value (default = undef).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'value' => 'This is value',
);
$ret = $obj->value;
is($ret, 'This is value', 'Get value (This is value).');
