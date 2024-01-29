use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Textarea->new;
my $ret = $obj->name;
is($ret, undef, 'Get name (default = undef).');

# Test.
$obj = Data::HTML::Textarea->new(
	'name' => 'foo',
);
$ret = $obj->name;
is($ret, 'foo', 'Get name (foo).');
