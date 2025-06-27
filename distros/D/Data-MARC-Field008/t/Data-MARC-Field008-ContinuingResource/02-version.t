use strict;
use warnings;

use Data::MARC::Field008::ContinuingResource;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Field008::ContinuingResource::VERSION, 0.03, 'Version.');
