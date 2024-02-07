use strict;
use warnings;

use Data::HTML::Element::Option;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Option->new;
isa_ok($obj, 'Data::HTML::Element::Option');

# Test.
$obj = Data::HTML::Element::Option->new(
	'css_class' => 'input',
	'data' => ['simple button'],
	'data_type' => 'plain',
	'disabled' => 1,
	'form' => 'form-id',
	'id' => 'ID',
	'label' => 'Label',
	'selected' => 1,
	'value' => 'foo',
);
isa_ok($obj, 'Data::HTML::Element::Option');

# Test.
$obj = Data::HTML::Element::Option->new(
	'css_class' => 'input',
	'data' => [['d', 'simple button']],
	'data_type' => 'tags',
	'disabled' => 1,
	'form' => 'form-id',
	'id' => 'ID',
	'label' => 'Label',
	'selected' => 1,
	'value' => 'foo',
);
isa_ok($obj, 'Data::HTML::Element::Option');

# Test
eval {
	Data::HTML::Element::Option->new(
		'css_class' => '@bad',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name.\n",
	"Parameter 'css_class' has bad CSS class name (\@bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'data_type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'data_type' has bad value.\n",
	"Parameter 'data_type' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'data' => 'bad',
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' must be a array.\n",
	"Parameter 'data' must be a array.");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'data' => [[]],
		'data_type' => 'plain',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'plain' mode must contain reference to array with scalars.\n",
	"Parameter 'data' in 'plain' mode must contain reference to array with scalars.");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'data' => ['bad'],
		'data_type' => 'tags',
	);
};
is($EVAL_ERROR, "Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.\n",
	"Parameter 'data' in 'tags' mode must contain reference to array with references to array with Tags structure.");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'disabled' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'disabled' must be a bool (0/1).\n",
	"Parameter 'disabled' must be a bool (0/1) (bad).");
clean();

# Test.
eval {
	Data::HTML::Element::Option->new(
		'selected' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'selected' must be a bool (0/1).\n",
	"Parameter 'selected' must be a bool (0/1) (bad).");
clean();
