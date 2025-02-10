use strict;
use warnings;

use Data::Icon;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Icon->new;
my $ret = $obj->alt;
is($ret, undef, 'Get alternamte text (undef).');

# Test.
$obj = Data::Icon->new(
	'alt' => 'Foo icon',
	'url' => 'https://examples.com/foo.ico',
);
$ret = $obj->alt;
is($ret, 'Foo icon', 'Get alternamte text (Foo icon).');
