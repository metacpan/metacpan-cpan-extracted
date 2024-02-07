use strict;
use warnings;

use Data::Login::Role;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Login::Role::VERSION, 0.01, 'Version.');
