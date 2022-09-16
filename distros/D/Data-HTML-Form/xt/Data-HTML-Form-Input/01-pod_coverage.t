use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::HTML::Form::Input', 'Data::HTML::Form::Input is covered.');
