use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
is($obj->checked, 0, 'Get checked (0 - default).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'checked' => undef,
);
is($obj->checked, 0, 'Get checked (undef).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'checked' => 1,
);
is($obj->checked, 1, 'Get checked (1).');
