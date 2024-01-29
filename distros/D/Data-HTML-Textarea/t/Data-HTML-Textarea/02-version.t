use strict;
use warnings;

use Data::HTML::Textarea;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Textarea::VERSION, 0.02, 'Version.');
