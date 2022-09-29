use strict;
use warnings;

use Data::HTML::Form::Input;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Form::Input::VERSION, 0.04, 'Version.');
