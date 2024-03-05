use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->desc, undef, 'Get description (undef - default).');

# Test.
$obj = Data::Navigation::Item->new(
	'desc' => 'This is description',
	'title' => 'Title',
);
is($obj->desc, 'This is description', 'Get description (This is description).');
