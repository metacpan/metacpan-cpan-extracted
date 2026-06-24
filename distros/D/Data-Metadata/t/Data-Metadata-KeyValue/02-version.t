use strict;
use warnings;

use Data::Metadata::KeyValue;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Metadata::KeyValue::VERSION, 0.01, 'Version.');
