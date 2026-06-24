use strict;
use warnings;

use Data::Image;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Image::VERSION, 0.06, 'Version.');
