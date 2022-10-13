use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->comment, undef, 'Get comment (undef - default value).');

# Test.
$obj = Data::Commons::Image->new(
	'comment' => 'Michal from Czechia',
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->comment, 'Michal from Czechia', 'Get comment (Michal from Czechia)');
