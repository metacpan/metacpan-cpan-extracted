use strict;
use warnings;

use Data::HTML::Element::A;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::A::VERSION, 0.16, 'Version.');
