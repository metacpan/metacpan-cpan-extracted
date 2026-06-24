use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new(
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->width, undef, 'Get width (undef = default).');

# Test.
$obj = Data::Image->new(
	'width' => 4096,
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->width, 4096, 'Get width (4096).');
