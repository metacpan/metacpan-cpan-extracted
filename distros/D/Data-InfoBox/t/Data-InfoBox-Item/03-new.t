use strict;
use warnings;

use Data::Icon;
use Data::InfoBox::Item;
use Data::Text::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::InfoBox::Item->new(
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon' => Data::Icon->new(
		'url' => 'https://example.com/icon.ico',
	),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'uri' => 'https://example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon' => Data::Icon->new(
		'url' => 'images/icon.ico',
	),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'uri' => 'https://example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon' => Data::Icon->new(
		'char' => decode_utf8('⌂'),
	),
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'uri' => 'https://example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'text' => Data::Text::Simple->new(
		'text' => 'john@example.com',
	),
	'uri' => 'mailto:john@example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
eval {
	Data::InfoBox::Item->new(
		'icon' => 'bad',
		'text' => Data::Text::Simple->new(
			'text' => 'Text',
		),
	);
};
is($EVAL_ERROR, "Parameter 'icon' must be a 'Data::Icon' object.\n",
	"Parameter 'icon' must be a 'Data::Icon' object. (bad).");
clean();

# Test.
eval {
	Data::InfoBox::Item->new;
};
is($EVAL_ERROR, "Parameter 'text' is required.\n",
	"Parameter 'text' is required.");
clean();

# Test.
eval {
	Data::InfoBox::Item->new(
		'text' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'text' must be a 'Data::Text::Simple' object.\n",
	"Parameter 'text' must be a 'Data::Text::Simple' object (bad).");
clean();
