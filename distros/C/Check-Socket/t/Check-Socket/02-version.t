use strict;
use warnings;

use Check::Socket;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Check::Socket::VERSION, 0.02, 'Version.');
