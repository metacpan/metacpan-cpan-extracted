use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Test.
my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new;
is($obj->id, 7, 'Get id (7)');
