use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::HTML::Form::Input;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Form::Input->new;
isa_ok($obj, 'Data::HTML::Form::Input');

# Test.
$obj = Data::HTML::Form::Input->new(
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
isa_ok($obj, 'Data::HTML::Form::Input');

# Test.
eval {
	Data::HTML::Form::Input->new(
		'type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'type' has bad value.\n",
	"Parameter 'type' has bad value.");
clean();
