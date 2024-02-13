use strict;
use warnings;

use Data::HTML::Element::Button;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Button::VERSION, 0.11, 'Version.');
