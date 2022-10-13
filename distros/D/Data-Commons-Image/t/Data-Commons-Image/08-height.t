use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->height, undef, 'Get height (undef = default).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'height' => 2730,
);
is($obj->height, 2730, 'Get height (2730).');
