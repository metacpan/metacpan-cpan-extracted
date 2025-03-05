use strict;
use warnings;

use Data::ExternalId;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::ExternalId::VERSION, 0.01, 'Version.');
