use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->placeholder;
is($ret, undef, 'Get placeholder (default = undef).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'placeholder' => 'foo',
);
$ret = $obj->placeholder;
is($ret, 'foo', 'Get placeholder (foo).');
