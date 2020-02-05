use strict;
use warnings;

use CGI::Pure::Save;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CGI::Pure::Save::VERSION, 0.08, 'Version.');
