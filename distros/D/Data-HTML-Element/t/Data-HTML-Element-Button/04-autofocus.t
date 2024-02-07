use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
is($obj->autofocus, 0, 'Get autofocus (0 - default).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'autofocus' => undef,
);
is($obj->autofocus, 0, 'Get autofocus (0 - undef).');

# Test.
$obj = Data::HTML::Element::Button->new(
	'autofocus' => 1,
);
is($obj->autofocus, 1, 'Get autofocus (1).');
