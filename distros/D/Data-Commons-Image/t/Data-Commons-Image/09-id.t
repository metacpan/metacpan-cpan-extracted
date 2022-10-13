use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->id, undef, 'Get id (undef - default value).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'id' => 1,
);
is($obj->id, 1, 'Get id (1)');
