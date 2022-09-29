use strict;
use warnings;

use Data::HTML::Form;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Form->new;
is($obj->method, 'get', 'Get method (get - default).');

# Test.
$obj = Data::HTML::Form->new(
	'method' => 'post',
);
is($obj->method, 'post', 'Get method (post).');
