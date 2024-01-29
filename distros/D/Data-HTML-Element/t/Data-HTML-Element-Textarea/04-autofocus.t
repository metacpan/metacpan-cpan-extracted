use strict;
use warnings;

use Data::HTML::Element::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
my $ret = $obj->autofocus;
is($ret, 0, 'Get autofocus flag (default = 0).');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'autofocus' => 1,
);
$ret = $obj->autofocus;
is($ret, 1, 'Get autofocus flag (1).');
