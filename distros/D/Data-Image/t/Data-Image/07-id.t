use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Image->new;
is($obj->id, undef, 'Get id (undef - default value).');

# Test.
$obj = Data::Image->new(
	'id' => 1,
);
is($obj->id, 1, 'Get id (1)');
