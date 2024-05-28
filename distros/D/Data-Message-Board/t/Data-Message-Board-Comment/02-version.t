use strict;
use warnings;

use Data::Message::Board::Comment;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Message::Board::Comment::VERSION, 0.05, 'Version.');
