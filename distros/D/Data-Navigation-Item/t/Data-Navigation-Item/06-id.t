use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::Navigation::Item->new(
	'id' => 7,
	'title' => 'Title',
);
is($obj->id, 7, 'Get id (7).');
