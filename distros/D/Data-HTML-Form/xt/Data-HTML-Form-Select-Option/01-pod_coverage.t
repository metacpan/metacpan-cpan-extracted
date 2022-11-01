use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::HTML::Form::Select::Option', 'Data::HTML::Form::Select::Option is covered.');
