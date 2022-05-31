use strict;
use warnings;

use Commons::Link;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Commons::Link::VERSION, 0.07, 'Version.');
