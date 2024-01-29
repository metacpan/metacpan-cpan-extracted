use strict;
use warnings;

use Data::HTML::Element::Select;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
isa_ok($obj, 'Data::HTML::Element::Select');

# Test.
$obj = Data::HTML::Element::Select->new(
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
isa_ok($obj, 'Data::HTML::Element::Select');

# Test.
eval {
	Data::HTML::Element::Select->new(
		'autofocus' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'autofocus' must be a bool (0/1).\n",
	"Parameter 'autofocus' must be a bool (0/1).");
clean();
