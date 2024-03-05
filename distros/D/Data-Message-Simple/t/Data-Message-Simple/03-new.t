use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Data::Message::Simple->new(
	'text' => 'This is message.',
);
isa_ok($obj, 'Data::Message::Simple');

# Test.
$obj = Data::Message::Simple->new(
	'lang' => 'en',
	'text' => 'This is message.',
	'type' => 'error',
);
isa_ok($obj, 'Data::Message::Simple');

# Test.
eval {
	Data::Message::Simple->new;
};
is($EVAL_ERROR, "Parameter 'text' is required.\n",
	"Parameter 'text' is required.");
clean();

# Test.
eval {
	Data::Message::Simple->new(
		'text' => ('a' x 5000),
	);
};
is($EVAL_ERROR, "Parameter 'text' has length greater than '4096'.\n",
	"Parameter 'text' has length greater than '4096'.");
clean();

# Test.
eval {
	Data::Message::Simple->new(
		'lang' => 'xx',
		'text' => 'This is message.',
	),
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-1 code (xx).");
clean();

# Test.
eval {
	Data::Message::Simple->new(
		'text' => 'This is message.',
		'type' => 'bad_type',
	),
};
is($EVAL_ERROR, "Parameter 'type' must be one of defined strings.\n",
	"Parameter 'type' must be one of defined strings.");
clean();
