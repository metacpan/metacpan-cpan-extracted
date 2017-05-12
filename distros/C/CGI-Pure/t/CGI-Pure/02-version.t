# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CGI::Pure::VERSION, 0.05, 'Version.');
