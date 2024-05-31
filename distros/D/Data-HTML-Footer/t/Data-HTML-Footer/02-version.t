use strict;
use warnings;

use Data::HTML::Footer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::HTML::Footer::VERSION, 0.01, 'Version.');
