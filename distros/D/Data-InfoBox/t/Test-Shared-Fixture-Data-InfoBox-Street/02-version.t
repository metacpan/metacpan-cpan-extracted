use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Street;

# Test.
is($Test::Shared::Fixture::Data::InfoBox::Street::VERSION, 0.03, 'Version.');
