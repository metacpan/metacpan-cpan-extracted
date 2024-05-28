use strict;
use warnings;

use Test::More 'tests' => 4;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::Message::Board::Example;

# Test.
my $obj = Test::Shared::Fixture::Data::Message::Board::Example->new;
my @ret = @{$obj->comments};
is(@ret, 2, 'Get comments (2 items).');
isa_ok($ret[0], 'Data::Message::Board::Comment');
isa_ok($ret[1], 'Data::Message::Board::Comment');
