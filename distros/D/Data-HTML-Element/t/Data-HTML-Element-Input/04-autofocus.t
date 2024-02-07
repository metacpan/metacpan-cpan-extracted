use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
is($obj->autofocus, 0, 'Get autofocus (0 - default).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'autofocus' => undef,
);
is($obj->autofocus, 0, 'Get autofocus (undef).');

# Test.
$obj = Data::HTML::Element::Input->new(
	'autofocus' => 1,
);
is($obj->autofocus, 1, 'Get autofocus (1).');
