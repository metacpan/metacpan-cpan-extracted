use strict;
use warnings;

use Data::OFN::Common;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::OFN::Common::VERSION, 0.02, 'Version.');
