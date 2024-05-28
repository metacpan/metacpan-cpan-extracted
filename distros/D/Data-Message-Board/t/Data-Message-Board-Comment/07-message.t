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
is($obj->message, 'This is message.', 'Get messsage (This is message.).');
