use strict;
use warnings;

use Data::HTML::Element::Option;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Option->new;
is($obj->value, undef, 'Get value (undef - default).');

# Test.
$obj = Data::HTML::Element::Option->new(
	'value' => 1,
);
is($obj->value, 1, 'Get value (1).');
