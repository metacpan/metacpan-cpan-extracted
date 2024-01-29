use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->id;
is($ret, undef, 'Get id (default = undef).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'id' => 'foo',
);
$ret = $obj->id;
is($ret, 'foo', 'Get id (foo).');
