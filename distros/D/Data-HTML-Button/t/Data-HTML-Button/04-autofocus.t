use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->autofocus, 0, 'Get autofocus (0 - default).');

# Test.
$obj = Data::HTML::Button->new(
	'autofocus' => undef,
);
is($obj->autofocus, 0, 'Get autofocus (undef).');

# Test.
$obj = Data::HTML::Button->new(
	'autofocus' => 1,
);
is($obj->autofocus, 1, 'Get autofocus (1).');
