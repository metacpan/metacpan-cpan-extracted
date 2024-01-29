use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Textarea->new;
my $ret = $obj->label;
is($ret, undef, 'Get label (default = undef).');

# Test.
$obj = Data::HTML::Textarea->new(
	'label' => 'foo',
);
$ret = $obj->label;
is($ret, 'foo', 'Get label (foo).');
