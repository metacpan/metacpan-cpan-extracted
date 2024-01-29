use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Textarea->new;
my $ret = $obj->cols;
is($ret, undef, 'Get columns number (default = undef).');

# Test.
$obj = Data::HTML::Textarea->new(
	'cols' => 2,
);
$ret = $obj->cols;
is($ret, 2, 'Get columns number (2).');
