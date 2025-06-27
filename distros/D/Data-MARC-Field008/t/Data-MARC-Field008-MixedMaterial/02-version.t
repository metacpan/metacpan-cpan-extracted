use strict;
use warnings;

use Data::MARC::Field008::MixedMaterial;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Field008::MixedMaterial::VERSION, 0.03, 'Version.');
