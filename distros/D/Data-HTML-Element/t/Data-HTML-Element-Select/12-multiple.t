use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
is($obj->multiple, 0, 'Get multiple (0 - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'multiple' => undef,
);
is($obj->multiple, 0, 'Get multiple (0 - undef).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'multiple' => 1,
);
is($obj->multiple, 1, 'Get multiple (1).');
