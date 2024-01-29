use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->disabled;
is($ret, 0, 'Get disabled flag (default = 0).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'disabled' => 1,
);
$ret = $obj->disabled;
is($ret, 1, 'Get disabled flag (1).');
