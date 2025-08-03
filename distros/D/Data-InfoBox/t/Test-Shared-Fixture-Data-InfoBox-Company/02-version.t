use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Company;

# Test.
is($Test::Shared::Fixture::Data::InfoBox::Company::VERSION, 0.07, 'Version.');
