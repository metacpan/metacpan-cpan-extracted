use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Business::UDC->new('811.112.2');
is($obj->source, '811.112.2', 'Get source (811.112.2).');
