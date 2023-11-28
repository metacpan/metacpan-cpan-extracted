use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader::Utils->new;
isa_ok($obj, 'Data::MARC::Leader::Utils');
