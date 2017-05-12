# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure::Fast;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CGI::Pure::Fast::VERSION, 0.06, 'Version.');
