use strict;
use warnings;

use Data::Message::Board;
use Data::Person;
use DateTime;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Board->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'message' => 'This is message.',
);
isa_ok($obj->date, 'DateTime');
