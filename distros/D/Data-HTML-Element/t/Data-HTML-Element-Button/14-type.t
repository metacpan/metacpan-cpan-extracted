use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
is($obj->type, 'button', 'Get type (button - default).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'type' => 'reset',
);
is($obj->type, 'reset', 'Get type (reset).');
