use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
is($obj->image, undef, 'Get image (undef - default).');

# Test.
$obj = Data::Navigation::Item->new(
	'image' => 'foo.png',
	'title' => 'Title',
);
is($obj->image, 'foo.png', 'Get image (foo.png).');
