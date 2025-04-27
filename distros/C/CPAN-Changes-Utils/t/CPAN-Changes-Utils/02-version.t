use strict;
use warnings;

use CPAN::Changes::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CPAN::Changes::Utils::VERSION, 0.02, 'Version.');
