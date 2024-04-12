use strict;
use warnings;

use Data::HTML::Element::Input;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Input->new;
isa_ok($obj, 'Data::HTML::Element::Input');

# Test.
$obj = Data::HTML::Element::Input->new(
	'checked' => 0,
	'css_class' => 'input',
	'disabled' => 1,
	'id' => 'ID',
	'label' => 'Label',
	'max' => 5,
	'min' => 1,
	'placeholder' => 'placeholder',
	'readonly' => 1,
	'required' => 1,
	'size' => 2,
	'value' => 'Foo bar',
	'type' => 'text',
);
isa_ok($obj, 'Data::HTML::Element::Input');

# Test.
$obj = Data::HTML::Element::Input->new(
	'step' => 'any',
	'type' => 'range',
);
isa_ok($obj, 'Data::HTML::Element::Input');

# Test.
$obj = Data::HTML::Element::Input->new(
	'step' => 2,
	'type' => 'number',
);
isa_ok($obj, 'Data::HTML::Element::Input');

# Test.
$obj = Data::HTML::Element::Input->new(
	'step' => 0.000001,
	'type' => 'number',
);
isa_ok($obj, 'Data::HTML::Element::Input');

# Test.
eval {
	Data::HTML::Element::Input->new(
		'type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'type' has bad value.\n",
	"Parameter 'type' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Input->new(
		'step' => 'bad',
		'type' => 'range',
	);
};
is($EVAL_ERROR, "Parameter 'step' must be a number or 'any' string.\n",
	"Parameter 'step' must be a number or 'any' string (bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Input->new(
		'step' => 'any',
		'type' => 'text',
	);
};
is($EVAL_ERROR, "Parameter 'step' is not valid for defined type.\n",
	"Parameter 'step' is not valid for defined type (text).");
clean();
