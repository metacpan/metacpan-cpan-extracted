use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new(
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->author, undef, 'Get author name (undef = default).');

# Test.
$obj = Data::Image->new(
	'author' => 'Zuzana Zonova',
	'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
);
is($obj->author, 'Zuzana Zonova', 'Get author name.');
