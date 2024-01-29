use strict;
use warnings;

use Data::HTML::Element::A;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::A->new;
is($obj->data_type, 'plain', 'Get data type (plain - default).');

# Test.
$obj = Data::HTML::Element::A->new(
	'data_type' => 'tags',
);
is($obj->data_type, 'tags', 'Get data type (tags).');
