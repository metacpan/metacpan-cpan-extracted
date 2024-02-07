use strict;
use warnings;

use Data::HTML::Element::Option;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Option->new;
is($obj->selected, 0, 'Get selected (0 - default).');

# Test.
$obj = Data::HTML::Element::Option->new(
	'selected' => undef,
);
is($obj->selected, 0, 'Get selected (0 - undef).');

# Test.
$obj = Data::HTML::Element::Option->new(
	'selected' => 1,
);
is($obj->selected, 1, 'Get selected (1).');
