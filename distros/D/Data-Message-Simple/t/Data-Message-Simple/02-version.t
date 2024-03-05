use strict;
use warnings;

use Data::Message::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Message::Simple::VERSION, 0.03, 'Version.');
