use strict;
use warnings;

use Data::Login;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Login::VERSION, 0.03, 'Version.');
