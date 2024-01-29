use strict;
use warnings;

use Data::HTML::Element::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Element::Form::VERSION, 0.09, 'Version.');
