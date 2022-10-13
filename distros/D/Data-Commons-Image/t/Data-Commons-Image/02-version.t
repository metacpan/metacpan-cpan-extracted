use strict;
use warnings;

use Data::Commons::Image;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Commons::Image::VERSION, 0.03, 'Version.');
