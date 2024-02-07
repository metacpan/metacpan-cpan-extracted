use strict;
use warnings;

use Data::HTML::Element::Select;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Select->new;
isa_ok($obj, 'Data::HTML::Element::Select');

# Test.
$obj = Data::HTML::Element::Select->new(
	'autofocus' => 0,
	'css_class' => 'input',
	'data' => ['<option>Value</option>'],
	'data_type' => 'plain',
	'disabled' => 1,
	'form' => 'form-id',
	'id' => 'ID',
	'label' => 'Label',
	'multimple' => 1,
	'name' => 'Select name',
	'required' => 1,
	'size' => 2,
);
isa_ok($obj, 'Data::HTML::Element::Select');

# Test.
$obj = Data::HTML::Element::Select->new(
	'autofocus' => 0,
	'css_class' => 'input',
	'data' => [
		['b', 'option'],
		['d', 'Value'],
		['e', 'option'],
	],
	'data_type' => 'tags',
	'disabled' => 1,
	'form' => 'form-id',
	'id' => 'ID',
	'label' => 'Label',
	'multimple' => 1,
	'name' => 'Select name',
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
	"Parameter 'autofocus' must be a bool (0/1) (bad).");
clean();

# Test
eval {
	Data::HTML::Element::Select->new(
		'css_class' => '@bad',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name.\n",
	"Parameter 'css_class' has bad CSS class name (\@bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'data_type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'data_type' has bad value.\n",
	"Parameter 'data_type' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'data' => 'bad',
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' must be a array.\n",
	"Parameter 'data' must be a array.");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'data' => [[]],
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'plain' mode must contain reference to array with scalars.\n",
	"Parameter 'data' in 'plain' mode must contain reference to array with scalars.");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'data' => ['bad'],
		'data_type' => 'tags',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.\n",
	"Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'disabled' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'disabled' must be a bool (0/1).\n",
	"Parameter 'disabled' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'multiple' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'multiple' must be a bool (0/1).\n",
	"Parameter 'multiple' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'required' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'required' must be a bool (0/1).\n",
	"Parameter 'required' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Select->new(
		'size' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'size' must be a number.\n",
	"Parameter 'size' must be a number (bad).");
clean();
