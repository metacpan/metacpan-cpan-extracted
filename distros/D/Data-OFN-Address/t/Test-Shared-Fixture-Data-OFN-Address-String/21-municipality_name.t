use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::String;

# Test.
my $obj = Test::Shared::Fixture::Data::OFN::Address::String->new;
is_deeply($obj->municipality_name, [], 'Get municipality name (reference to blank array - default).');
