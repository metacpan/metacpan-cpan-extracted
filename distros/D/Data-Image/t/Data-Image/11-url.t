use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
is($obj->url, undef, 'Get URL (undef - default value).');

# Test.
$obj = Data::Image->new(
	'url' => 'https://example.com/foo.jpg',
);
is($obj->url, 'https://example.com/foo.jpg', 'Get URL (https://example.com/foo.jpg)');
