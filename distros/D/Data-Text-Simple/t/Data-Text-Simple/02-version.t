use strict;
use warnings;

use Data::Text::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Text::Simple::VERSION, 0.02, 'Version.');
