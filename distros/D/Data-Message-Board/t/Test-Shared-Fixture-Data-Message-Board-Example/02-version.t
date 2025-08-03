use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Test.
is($Test::Shared::Fixture::Data::Message::Board::Example::VERSION, 0.06, 'Version.');
