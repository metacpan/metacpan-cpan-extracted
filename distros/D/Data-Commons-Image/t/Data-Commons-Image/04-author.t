use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->author, undef, 'Get author name (undef = default).');

# Test.
$obj = Data::Commons::Image->new(
	'author' => 'Zuzana Zonova',
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->author, 'Zuzana Zonova', 'Get author name.');
