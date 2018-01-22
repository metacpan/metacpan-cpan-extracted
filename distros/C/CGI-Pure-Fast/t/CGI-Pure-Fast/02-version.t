use strict;
use warnings;

use CGI::Pure::Fast;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CGI::Pure::Fast::VERSION, 0.08, 'Version.');
