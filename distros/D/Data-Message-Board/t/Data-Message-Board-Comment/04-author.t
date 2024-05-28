use strict;
use warnings;

use Data::Message::Board::Comment;
use Data::Person;
use DateTime;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Board::Comment->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'message' => 'This is message.',
);
isa_ok($obj->author, 'Data::Person');
