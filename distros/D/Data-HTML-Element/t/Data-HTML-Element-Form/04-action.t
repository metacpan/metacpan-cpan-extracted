use strict;
use warnings;

use Data::HTML::Element::Form;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Form->new;
is($obj->action, undef, 'Get action (undef - default).');

# Test.
$obj = Data::HTML::Element::Form->new(
	'action' => '/action',
);
is($obj->action, '/action', 'Get action (/action).');
