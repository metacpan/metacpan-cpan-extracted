use strict;
use warnings;

use Data::HTML::Element::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Select::VERSION, 0.15, 'Version.');
