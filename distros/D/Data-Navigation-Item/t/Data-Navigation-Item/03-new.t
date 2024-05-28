use strict;
use warnings;

use Data::Navigation::Item;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Data::Navigation::Item->new(
	'title' => 'Title',
);
isa_ok($obj, 'Data::Navigation::Item');

# Test.
$obj = Data::Navigation::Item->new(
	'class' => 'item-class',
	'desc' => 'This is description',
	'id' => 1,
	'image' => '/img/foo.png',
	'location' => '/title',
	'title' => 'Title',
);
isa_ok($obj, 'Data::Navigation::Item');

# Test.
eval {
	Data::Navigation::Item->new;
};
is($EVAL_ERROR, "Parameter 'title' is required.\n",
	"Parameter 'title' is required.");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'class' => '1bad',
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'class' has bad CSS class name (number on begin).\n",
	"Parameter 'class' has bad CSS class name (number on begin).");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'class' => '@bad',
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'class' has bad CSS class name.\n",
	"Parameter 'class' has bad CSS class name.");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'desc' => 'a' x 1001,
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'desc' has length greater than '1000'.\n",
	"Parameter 'desc' has length greater than '1000'.");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'id' => 'bad',
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a natural number.\n",
	"Parameter 'id' must be a natural number.");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'image' => 'urn:isbn:0451450523',
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'image' doesn't contain valid location.\n",
	"Parameter 'image' doesn't contain valid location (urn:isbn:0451450523).");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'location' => 'urn:isbn:0451450523',
		'title' => 'Title',
	);
};
is($EVAL_ERROR, "Parameter 'location' doesn't contain valid location.\n",
	"Parameter 'location' doesn't contain valid location (urn:isbn:0451450523).");
clean();

# Test.
eval {
	Data::Navigation::Item->new(
		'title' => 'a' x 101,
	);
};
is($EVAL_ERROR, "Parameter 'title' has length greater than '100'.\n",
	"Parameter 'title' has length greater than '100'.");
clean();
