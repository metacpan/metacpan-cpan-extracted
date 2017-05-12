# Pragmas.
use strict;
use warnings;

# Modules.
use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::Video::Generator', 'App::Video::Generator is covered.');
