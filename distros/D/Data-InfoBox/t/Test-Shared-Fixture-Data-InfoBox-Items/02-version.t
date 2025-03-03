use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Items;

# Test.
is($Test::Shared::Fixture::Data::InfoBox::Items::VERSION, 0.06, 'Version.');
