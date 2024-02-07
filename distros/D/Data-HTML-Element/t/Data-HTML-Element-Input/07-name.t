use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
is($obj->name, undef, 'Get name (undef - default).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'name' => undef,
);
is($obj->name, undef, 'Get name (undef).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'name' => 'foo',
);
is($obj->name, 'foo', 'Get name (foo).');
