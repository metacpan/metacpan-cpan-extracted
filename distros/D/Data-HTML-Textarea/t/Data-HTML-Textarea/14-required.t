use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Textarea->new;
my $ret = $obj->required;
is($ret, 0, 'Get required flag (default = 0).');

# Test.
$obj = Data::HTML::Textarea->new(
	'required' => 1,
);
$ret = $obj->required;
is($ret, 1, 'Get required flag (1).');
