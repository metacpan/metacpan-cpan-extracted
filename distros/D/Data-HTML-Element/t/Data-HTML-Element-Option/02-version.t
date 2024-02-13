use strict;
use warnings;

use Data::HTML::Element::Option;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Option::VERSION, 0.11, 'Version.');
