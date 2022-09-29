use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->id, undef, 'Get id (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'id' => 'foo',
);
is($obj->id, 'foo', 'Get id (foo).');
