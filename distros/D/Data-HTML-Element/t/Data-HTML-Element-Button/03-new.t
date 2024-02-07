use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::HTML::Element::Button;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Button->new;
isa_ok($obj, 'Data::HTML::Element::Button');

# Test.
$obj = Data::HTML::Element::Button->new(
	'autofocus' => 1,
	'css_class' => 'button-nice',
	'data' => ['simple button'],
	'data_type' => 'plain',
	'disabled' => 0,
	'form_enctype' => 'text/plain',
	'form_method' => 'get',
	'form_no_validate' => 0,
	'id' => 'simple-button',
	'label' => 'Simple button',
	'name' => 'simple_button',
	'type' => 'submit',
	'value' => 10,
);
isa_ok($obj, 'Data::HTML::Element::Button');

# Test.
$obj = Data::HTML::Element::Button->new(
	'autofocus' => 1,
	'css_class' => 'button-nice',
	'data' => [['d', 'simple button']],
	'data_type' => 'tags',
	'disabled' => 0,
	'form_enctype' => 'text/plain',
	'form_method' => 'get',
	'form_no_validate' => 0,
	'id' => 'simple-button',
	'label' => 'Simple button',
	'name' => 'simple_button',
	'type' => 'submit',
	'value' => 10,
);
isa_ok($obj, 'Data::HTML::Element::Button');

# Test.
eval {
	Data::HTML::Element::Button->new(
		'autofocus' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'autofocus' must be a bool (0/1).\n",
	"Parameter 'autofocus' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'data_type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'data_type' has bad value.\n",
	"Parameter 'data_type' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'data' => 'bad',
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' must be a array.\n",
	"Parameter 'data' must be a array.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'data' => [[]],
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'plain' mode must contain reference to array with scalars.\n",
	"Parameter 'data' in 'plain' mode must contain reference to array with scalars.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'data' => ['bad'],
		'data_type' => 'tags',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.\n",
	"Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'form_enctype' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'form_enctype' has bad value.\n",
	"Parameter 'form_enctype' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'form_method' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'form_method' has bad value.\n",
	"Parameter 'form_method' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'form_no_validate' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'form_no_validate' must be a bool (0/1).\n",
	"Parameter 'form_no_validate' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HTML::Element::Button->new(
		'type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'type' has bad value.\n",
	"Parameter 'type' has bad value.");
clean();
