use strict;
use warnings;

use Data::OFN::Common::TimeMoment;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::OFN::Common::TimeMoment::VERSION, 0.02, 'Version.');
