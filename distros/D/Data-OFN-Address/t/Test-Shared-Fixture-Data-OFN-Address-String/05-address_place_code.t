use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::String;

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::String->new;
is($obj->address_place_code, undef, 'Get address place code (undef).');
