use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
);
is($obj->url_cb, undef, 'Get URL callback (undef - default value).');

# Test.
$obj = Data::Commons::Image->new(
	'commons_name' => 'Michal from Czechia.jpg',
	'url_cb' => sub {
		my $name = shift;
		return 'https://example.com/'.$name;
	},
);
ok($obj->url_cb, 'Get URL callback.');
