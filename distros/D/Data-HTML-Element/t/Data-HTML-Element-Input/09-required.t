use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
is($obj->required, 0, 'Get required (0 - default).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'required' => undef,
);
is($obj->required, 0, 'Get required (undef).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'required' => 1,
);
is($obj->required, 1, 'Get required (1).');
