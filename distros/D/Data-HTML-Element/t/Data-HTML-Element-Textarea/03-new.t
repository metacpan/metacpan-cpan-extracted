use strict;
use warnings;

use Data::HTML::Element::Textarea;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Element::Textarea->new;
isa_ok($obj, 'Data::HTML::Element::Textarea');

# Test.
$obj = Data::HTML::Element::Textarea->new(
	'autofocus' => 1,
	'cols' => 2,
	'css_class' => 'input',
	'disabled' => 1,
	'form' => 'form',
	'id' => 'ID',
	'label' => 'Label',
	'name' => 'name',
	'placeholder' => 'placeholder',
	'readonly' => 1,
	'required' => 1,
	'rows' => 2,
	'value' => 'Foo bar',
);
isa_ok($obj, 'Data::HTML::Element::Textarea');

# Test.
eval {
	Data::HTML::Element::Textarea->new(
		'autofocus' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'autofocus' must be a bool (0/1).\n",
	"Parameter 'autofocus' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HTML::Element::Textarea->new(
		'disabled' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'disabled' must be a bool (0/1).\n",
	"Parameter 'disabled' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HTML::Element::Textarea->new(
		'readonly' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'readonly' must be a bool (0/1).\n",
	"Parameter 'readonly' must be a bool (0/1).");
clean();
