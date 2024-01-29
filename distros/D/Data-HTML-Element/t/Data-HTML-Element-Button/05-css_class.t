use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
is($obj->css_class, undef, 'Get CSS class (undef - default).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'css_class' => 'css-class',
);
is($obj->css_class, 'css-class', 'Get CSS class (css-class).');
