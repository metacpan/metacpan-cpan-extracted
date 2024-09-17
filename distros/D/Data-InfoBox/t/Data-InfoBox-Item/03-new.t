use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 10;
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
	'icon_url' => 'https://example.com/icon.ico',
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'uri' => 'https://example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon_url' => 'images/icon.ico',
	'text' => Data::Text::Simple->new(
		'text' => 'Text',
	),
	'uri' => 'https://example.com',
);
isa_ok($obj, 'Data::InfoBox::Item');

# Test.
$obj = Data::InfoBox::Item->new(
	'icon_char' => decode_utf8('⌂'),
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
		'icon_char' => 'bad',
		'text' => Data::Text::Simple->new(
			'text' => 'Text',
		),
	);
};
is($EVAL_ERROR, "Parameter 'icon_char' has length greater than '1'.\n",
	"Parameter 'icon_char' has length greater than '1' (bad).");
clean();

# Test.
eval {
	Data::InfoBox::Item->new(
		'icon_url' => 'urn:isbn:0451450523',
		'text' => Data::Text::Simple->new(
			'text' => 'Text',
		),
	);
};
is($EVAL_ERROR, "Parameter 'icon_url' doesn't contain valid location.\n",
	"Parameter 'icon_url' doesn't contain valid location (urn:isbn:0451450523).");
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
