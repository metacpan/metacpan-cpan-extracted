use strict;
use warnings;

use Data::Icon;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Icon->new;
isa_ok($obj, 'Data::Icon');

# Test.
$obj = Data::Icon->new(
	'alt' => 'Foo icon',
	'url' => 'https://examples.com/foo.ico',
);
isa_ok($obj, 'Data::Icon');

# Test.
$obj = Data::Icon->new(
	'bg_color' => 'grey',
	'char' => decode_utf8('†'),
	'color' => 'red',
);
isa_ok($obj, 'Data::Icon');

# Test.
eval {
	Data::Icon->new(
		'url' => 'urn:isbn:0451450523',
	);
};
is($EVAL_ERROR, "Parameter 'url' doesn't contain valid location.\n",
	"Parameter 'url' doesn't contain valid location (urn:isbn:0451450523).");
clean();

# Test.
eval {
	Data::Icon->new(
		'char' => 'x',
		'url' => 'https://examples.com/foo.ico',
	);
};
is($EVAL_ERROR, "Parameter 'url' is in conflict with parameter 'char'.\n",
	"Parameter 'url' is in conflict with parameter 'char'. (char and url are present).");
clean();

# Test.
eval {
	Data::Icon->new(
		'alt' => 'alternate text',
		'char' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'char' don't need parameter 'alt'.\n",
	"Parameter 'char' don't need parameter 'alt'. (char and alt are present).");
clean();

# Test.
eval {
	Data::Icon->new(
		'color' => 'red',
		'url' => 'https://examples.com/foo.ico',
	);
};
is($EVAL_ERROR, "Parameter 'url' don't need parameter 'color'.\n",
	"Parameter 'url' don't need parameter 'color'. (color and url are present).");
clean();

# Test.
eval {
	Data::Icon->new(
		'bg_color' => 'red',
		'url' => 'https://examples.com/foo.ico',
	);
};
is($EVAL_ERROR, "Parameter 'url' don't need parameter 'bg_color'.\n",
	"Parameter 'url' don't need parameter 'bg_color'. (bg_color and url are present).");
clean();
