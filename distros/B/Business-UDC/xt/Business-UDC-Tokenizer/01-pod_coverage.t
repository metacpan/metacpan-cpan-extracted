use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Business::UDC::Tokenizer', 'Business::UDC::Tokenizer is covered.');
