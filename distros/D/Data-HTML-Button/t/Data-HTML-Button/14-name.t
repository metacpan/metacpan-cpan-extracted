use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->name, undef, 'Get name (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'name' => 'foo',
);
is($obj->name, 'foo', 'Get name (foo).');
