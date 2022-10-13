use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new(
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->height, undef, 'Get height (undef = default).');

# Test.
$obj = Data::Image->new(
	'height' => 2730,
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->height, 2730, 'Get height (2730).');
