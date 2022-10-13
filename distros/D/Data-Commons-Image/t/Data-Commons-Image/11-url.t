use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->url, undef, 'Get URL (undef - default value).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'url' => 'https://example.com/foo.jpg',
);
is($obj->url, 'https://example.com/foo.jpg', 'Get URL (https://example.com/foo.jpg)');
