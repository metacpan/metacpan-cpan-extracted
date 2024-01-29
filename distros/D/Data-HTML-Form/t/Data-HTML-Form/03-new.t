use strict;
use warnings;

use Data::HTML::Form;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Data::HTML::Form->new;
isa_ok($obj, 'Data::HTML::Form');

# Test.
$obj = Data::HTML::Form->new(
	'action' => '/action',
	'css_class' => 'button-nice',
	'enctype' => 'text/plain',
	'id' => 'simple-button',
	'label' => 'Simple button',
	'method' => 'post',
);
isa_ok($obj, 'Data::HTML::Form');

# Test.
eval {
	Data::HTML::Form->new(
		'method' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'method' has bad value.\n",
	"Parameter 'method' has bad value.");
clean();

# Test.
eval {
	Data::HTML::Form->new(
		'enctype' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'enctype' has bad value.\n",
	"Parameter 'enctype' has bad value.");
clean();
