use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
is($obj->form_method, 'get', 'Get form method (get - default).');

# Test.
$obj = Data::HTML::Button->new(
	'form_method' => 'post',
);
is($obj->form_method, 'post', 'Get form method (post).');
