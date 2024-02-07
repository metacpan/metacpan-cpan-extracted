use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
is($obj->required, 0, 'Get required (0 - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'required' => undef,
);
is($obj->required, 0, 'Get required (0 - undef).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'required' => 1,
);
is($obj->required, 1, 'Get required (1).');
