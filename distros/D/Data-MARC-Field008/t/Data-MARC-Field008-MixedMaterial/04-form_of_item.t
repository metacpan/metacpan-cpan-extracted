use strict;
use warnings;

use Data::MARC::Field008::MixedMaterial;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::MixedMaterial->new(
	'form_of_item' => 'r',
);
is($obj->form_of_item, 'r', 'Get form of item (r).');
