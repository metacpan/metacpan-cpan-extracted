use strict;
use warnings;

use Data::Icon;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Icon->new;
my $ret = $obj->url;
is($ret, undef, 'Get URL (undef).');

# Test.
$obj = Data::Icon->new(
	'alt' => 'Foo icon',
	'url' => 'https://examples.com/foo.ico',
);
$ret = $obj->url;
is($ret, 'https://examples.com/foo.ico',
	'Get URL (https://examples.com/foo.ico).');
