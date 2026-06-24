use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
is($obj->url_cb, undef, 'Get URL callback (undef - default value).');

# Test.
$obj = Data::Image->new(
	'url_cb' => sub {
		my $name = shift;
		return 'https://example.com/'.$name;
	},
);
ok($obj->url_cb, 'Get URL callback.');
