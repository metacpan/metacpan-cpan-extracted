use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->class, undef, 'Get class (undef - default).');

# Test.
$obj = Data::Navigation::Item->new(
	'class' => 'item-class',
	'title' => 'Title',
);
is($obj->class, 'item-class', 'Get class (item-class).');
