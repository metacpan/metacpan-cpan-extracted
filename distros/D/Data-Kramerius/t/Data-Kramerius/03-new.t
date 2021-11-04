use strict;
use warnings;

use Data::Kramerius;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Kramerius->new;
isa_ok($obj, 'Data::Kramerius');
