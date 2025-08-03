use strict;
use warnings;

use Data::Message::Board;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Message::Board::VERSION, 0.06, 'Version.');
