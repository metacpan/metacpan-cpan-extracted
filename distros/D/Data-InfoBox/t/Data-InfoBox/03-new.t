use strict;
use warnings;

use Data::InfoBox;
use Data::InfoBox::Item;
use Data::Text::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::InfoBox->new(
	'items' => [
		Data::InfoBox::Item->new(
			'text' => Data::Text::Simple->new(
				'text' => 'foo',
			),
		),
	],
);
isa_ok($obj, 'Data::InfoBox');

# Test.
eval {
	Data::InfoBox->new;
};
is($EVAL_ERROR, "Parameter 'items' is required.\n",
	"Parameter 'items' is required.");
clean();

# Test.
eval {
	Data::InfoBox->new(
		'items' => [],
	);
};
is($EVAL_ERROR, "Parameter 'items' with array must have at least one item.\n",
	"Parameter 'items' with array must have at least one item.");
clean();

# Test.
eval {
	Data::InfoBox->new(
		'items' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'items' must be a array.\n",
	"Parameter 'items' must be a array.");
clean();
