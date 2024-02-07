use strict;
use warnings;

use Data::HTML::Element::Option;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Option->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HTML::Element::Option->new(
	'id' => 'foo',
);
is($obj->id, 'foo', 'Get id (foo).');
