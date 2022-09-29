use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->value, undef, 'Get value (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'value' => 1,
);
is($obj->value, 1, 'Get value (1).');
