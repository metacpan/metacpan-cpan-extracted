use strict;
use warnings;

use Data::HTML::Button;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Button::VERSION, 0.04, 'Version.');
