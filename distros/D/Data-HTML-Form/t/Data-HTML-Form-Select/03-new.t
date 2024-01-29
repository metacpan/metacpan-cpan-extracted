use strict;
use warnings;

use Data::HTML::Form::Select;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Form::Select->new;
isa_ok($obj, 'Data::HTML::Form::Select');

# Test.
$obj = Data::HTML::Form::Select->new(
	'autofocus' => 0,
	'css_class' => 'input',
	'disabled' => 1,
	'form' => 'form-id',
	'id' => 'ID',
	'label' => 'Label',
	'multimple' => 1,
	'name' => 'Select name',
	'options' => [],
	'required' => 1,
	'size' => 2,
);
isa_ok($obj, 'Data::HTML::Form::Select');

# Test.
eval {
	Data::HTML::Form::Select->new(
		'autofocus' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'autofocus' must be a bool (0/1).\n",
	"Parameter 'autofocus' must be a bool (0/1).");
clean();
