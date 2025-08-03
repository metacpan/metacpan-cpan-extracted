use strict;
use warnings;

use Data::Message::Board::Comment;
use Data::Person;
use DateTime;
use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Board::Comment->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'message' => 'This is message.',
);
isa_ok($obj, 'Data::Message::Board::Comment');

# Test.
$obj = Data::Message::Board::Comment->new(
	'author' => Data::Person->new,
	'date' => DateTime->now,
	'id' => 7,
	'message' => 'This is message.',
);
isa_ok($obj, 'Data::Message::Board::Comment');

# Test.
eval {
	Data::Message::Board::Comment->new(
		'date' => DateTime->now,
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'author' is required.\n",
	"Parameter 'author' is required.");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => 'bad',
		'date' => DateTime->now,
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'author' must be a 'Data::Person' object.\n",
	"Parameter 'author' must be a 'Data::Person' object (string).");
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Data::Message::Board::Comment->new(
		'author' => $mock,
		'date' => DateTime->now,
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'author' must be a 'Data::Person' object.\n",
	"Parameter 'author' must be a 'Data::Person' object (bad object).");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'date' is required.\n",
	"Parameter 'date' is required.");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'date' => 'bad',
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'date' must be a 'DateTime' object.\n",
	"Parameter 'date' must be a 'DateTime' object (bad).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'date' => $mock,
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'date' must be a 'DateTime' object.\n",
	"Parameter 'date' must be a 'DateTime' object (bad object).");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'date' => DateTime->now,
		'id' => 'bad',
		'message' => 'This is message.',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a positive natural number.\n",
	"Parameter 'id' must be a positive natural number (bad).");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'date' => DateTime->now,
	);
};
is($EVAL_ERROR, "Parameter 'message' is required.\n",
	"Parameter 'message' is required.");
clean();

# Test.
eval {
	Data::Message::Board::Comment->new(
		'author' => Data::Person->new,
		'date' => DateTime->now,
		'message' => ('a' x 5000),
	);
};
is($EVAL_ERROR, "Parameter 'message' has length greater than '4096'.\n",
	"Parameter 'message' has length greater than '4096'.");
clean();
