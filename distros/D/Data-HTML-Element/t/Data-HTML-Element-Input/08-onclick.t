use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
is($obj->onclick, undef, 'Get OnClick (undef - default).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'onclick' => undef,
);
is($obj->onclick, undef, 'Get OnClick (undef).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'name' => "alert('Hello world!')",
);
is($obj->name, "alert('Hello world!')", 'Get OnClick (alert(\'Hello world!\')).');
