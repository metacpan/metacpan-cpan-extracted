use strict;
use warnings;

use Data::HTML::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Form::VERSION, 0.04, 'Version.');
