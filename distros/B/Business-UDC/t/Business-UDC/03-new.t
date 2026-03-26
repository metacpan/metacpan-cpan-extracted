use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Business::UDC->new('0/9');
isa_ok($obj, 'Business::UDC');

# Test.
$obj = Business::UDC->new('bad');
isa_ok($obj, 'Business::UDC');

# Test.
$obj = Business::UDC->new();
isa_ok($obj, 'Business::UDC');
