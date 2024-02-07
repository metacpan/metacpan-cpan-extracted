use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
is($obj->css_class, undef, 'Get CSS class (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'css_class' => 'css-class',
);
is($obj->css_class, 'css-class', 'Get CSS class (css-class).');
