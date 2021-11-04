use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Commons::Link->new;
isa_ok($obj, 'Commons::Link');

# Test.
$obj = Commons::Link->new(
	'utf-8' => 0,
);
isa_ok($obj, 'Commons::Link');
