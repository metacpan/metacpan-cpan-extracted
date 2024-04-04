use strict;
use warnings;

use DateTime::Format::PDF;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($DateTime::Format::PDF::VERSION, 0.02, 'Version.');
