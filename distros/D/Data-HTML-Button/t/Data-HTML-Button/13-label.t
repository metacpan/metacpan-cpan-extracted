use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->label, undef, 'Get label (undef - default).');

# Test.
$obj = Data::HTML::Button->new(
	'label' => 'foo',
);
is($obj->label, 'foo', 'Get label (foo).');
