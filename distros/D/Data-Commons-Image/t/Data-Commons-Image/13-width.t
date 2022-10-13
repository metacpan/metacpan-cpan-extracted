use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->width, undef, 'Get width (undef = default).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'width' => 4096,
);
is($obj->width, 4096, 'Get width (4096).');
