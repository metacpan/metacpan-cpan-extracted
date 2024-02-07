use strict;
use warnings;

use Data::HTML::Element::Option;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Option->new;
is($obj->label, undef, 'Get label (undef - default).');

# Test.
$obj = Data::HTML::Element::Option->new(
	'label' => 'foo',
);
is($obj->label, 'foo', 'Get label (foo).');
