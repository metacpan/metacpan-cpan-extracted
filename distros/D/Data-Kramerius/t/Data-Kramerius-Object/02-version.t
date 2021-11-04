use strict;
use warnings;

use Data::Kramerius::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Kramerius::Object::VERSION, 0.03, 'Version.');
