use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Data::HTML::Button;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Button->new;
isa_ok($obj, 'Data::HTML::Button');

# Test.
$obj = Data::HTML::Button->new(
	'autofocus' => 1,
	'css_class' => 'button-nice',
	'data' => ['simple button'],
	'data_type' => 'plain',
	'disabled' => 0,
	'id' => 'simple-button',
	'label' => 'Simple button',
	'name' => 'simple_button',
	'type' => 'submit',
	'value' => 10,
);
isa_ok($obj, 'Data::HTML::Button');

# Test.
eval {
	Data::HTML::Button->new(
		'autofocus' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'autofocus' must be a bool (0/1).\n",
	"Parameter 'autofocus' must be a bool (0/1).");
clean();

# Test.
eval {
	Data::HTML::Button->new(
		'data_type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'data_type' has bad value.\n",
	"Parameter 'data_type' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Button->new(
		'type' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'type' has bad value.\n",
	"Parameter 'type' has bad value.");
clean();
