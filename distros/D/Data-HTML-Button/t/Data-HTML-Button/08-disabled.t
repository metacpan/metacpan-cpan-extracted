use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->disabled, 0, 'Get disabled (0 - default).');

# Test.
$obj = Data::HTML::Button->new(
	'disabled' => undef,
);
is($obj->disabled, 0, 'Get disabled (undef).');

# Test.
$obj = Data::HTML::Button->new(
	'disabled' => 1,
);
is($obj->disabled, 1, 'Get disabled (1).');
