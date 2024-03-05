use strict;
use warnings;

use Data::Text::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::Text::Simple->new(
	'text' => 'This is text.',
);
isa_ok($obj, 'Data::Text::Simple');

# Test.
$obj = Data::Text::Simple->new(
	'id' => 1,
	'lang' => 'en',
	'text' => 'This is text.',
);
isa_ok($obj, 'Data::Text::Simple');

# Test.
eval {
	Data::Text::Simple->new(
		'lang' => 'xx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-1 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-1 code.");
clean();

# Test.
eval {
	Data::Text::Simple->new(
		'id' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'id' must be a number.\n",
	"Parameter 'id' must be a number (bad).");
clean();

# Test.
eval {
	Data::Text::Simple->new;
};
is($EVAL_ERROR, "Parameter 'text' is required.\n",
	"Parameter 'text' is required.");
clean();
