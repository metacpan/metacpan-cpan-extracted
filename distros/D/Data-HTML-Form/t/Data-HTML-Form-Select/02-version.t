use strict;
use warnings;

use Data::HTML::Form::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Form::Select::VERSION, 0.05, 'Version.');
