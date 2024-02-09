use strict;
use warnings;

use Alt::Digest::MD5::OpenSSL;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alt::Digest::MD5::OpenSSL::VERSION, 0.04, 'Version.');
