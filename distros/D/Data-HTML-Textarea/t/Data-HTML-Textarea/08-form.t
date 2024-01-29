use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Textarea->new;
my $ret = $obj->form;
is($ret, undef, 'Get form id (default = undef).');

# Test.
$obj = Data::HTML::Textarea->new(
	'form' => 'foo',
);
$ret = $obj->form;
is($ret, 'foo', 'Get form id (foo).');
