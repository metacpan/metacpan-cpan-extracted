use strict;
use warnings;

use Data::Metadata;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Metadata::VERSION, 0.01, 'Version.');
