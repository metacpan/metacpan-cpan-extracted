use strict;
use warnings;

use Data::HTML::A;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::A::VERSION, 0.02, 'Version.');
