use strict;
use warnings;

use Data::HTML::Element::Form;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Form->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HTML::Element::Form->new(
	'id' => 'foo',
);
is($obj->id, 'foo', 'Get id (foo).');
