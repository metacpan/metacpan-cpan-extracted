use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Struct;

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::Struct->new;
is($obj->municipality_part, undef, 'Get municipality part (undef - default).');
