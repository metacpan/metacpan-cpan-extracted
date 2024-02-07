use strict;
use warnings;

use Data::HTML::Element::Form;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Form->new;
is($obj->label, undef, 'Get label (undef - default).');

# Test.
$obj = Data::HTML::Element::Form->new(
	'label' => 'foo',
);
is($obj->label, 'foo', 'Get label (foo).');
