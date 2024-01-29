use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'id' => 'foo',
);
is($obj->id, 'foo', 'Get id (foo).');
