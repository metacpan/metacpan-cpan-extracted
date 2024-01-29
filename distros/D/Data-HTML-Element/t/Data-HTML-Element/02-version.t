use strict;
use warnings;

use Data::HTML::Element;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::VERSION, 0.09, 'Version.');
