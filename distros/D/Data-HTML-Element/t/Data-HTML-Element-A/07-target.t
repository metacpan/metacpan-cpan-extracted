use strict;
use warnings;

use Data::HTML::Element::A;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::A->new;
is($obj->target, undef, 'Get target (undef).');

# Test.
$obj = Data::HTML::Element::A->new(
	'target' => '_blank',
);
is($obj->target, '_blank', 'Get target (_blank).');
