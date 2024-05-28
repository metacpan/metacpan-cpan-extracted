use strict;
use warnings;

use Data::Message::Board;
use Data::Person;
use DateTime;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Board->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'message' => 'This is message.',
);
is($obj->id, undef, 'Get id (undef - default)');

# Test.
$obj = Data::Message::Board->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'id' => 7,
	'message' => 'This is message.',
);
is($obj->id, 7, 'Get id (7)');
