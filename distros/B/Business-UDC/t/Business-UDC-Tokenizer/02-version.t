use strict;
use warnings;

use Business::UDC::Tokenizer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Business::UDC::Tokenizer::VERSION, 0.09, 'Version.');
