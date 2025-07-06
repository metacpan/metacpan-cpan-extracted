use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Struct;

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Struct->new;
is($obj->house_number, 12, 'Get house number (12).');
