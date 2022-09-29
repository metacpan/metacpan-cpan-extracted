use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->form, undef, 'Get form (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'form' => 'foo',
);
is($obj->form, 'foo', 'Get form (foo).');
