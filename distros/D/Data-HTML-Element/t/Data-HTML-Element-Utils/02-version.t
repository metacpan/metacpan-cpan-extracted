use strict;
use warnings;

use Data::HTML::Element::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Utils::VERSION, 0.16, 'Version.');
