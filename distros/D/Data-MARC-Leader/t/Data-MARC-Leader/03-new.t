use strict;
use warnings;

use Data::MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader->new;
isa_ok($obj, 'Data::MARC::Leader');
