use strict;
use warnings;

use Data::HTML::Element::Input;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Input::VERSION, 0.1, 'Version.');
