use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Street;

# Test.
my $obj = Test::Shared::Fixture::Data::InfoBox::Street->new;
isa_ok($obj, 'Test::Shared::Fixture::Data::InfoBox::Street');
