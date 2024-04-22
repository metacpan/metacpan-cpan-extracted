use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
my $ret = $obj->size;
is($ret, undef, 'Get size (undef - default).');

# Test.
$obj = Data::HTML::Element::Select->new(
	'size' => 12,
);
$ret = $obj->size;
is($ret, 12, 'Get size (12).');
