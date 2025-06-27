use strict;
use warnings;

use Data::MARC::Field008::Book;
use English;
use Error::Pure::Utils qw(clean err_get);
use Test::More 'tests' => 16;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::Book->new(
	'biography' => ' ',
	'conference_publication' => '0',
	'festschrift' => '0',
	'form_of_item' => 'r',
	'government_publication' => ' ',
	'illustrations' => '    ',
	'index' => '0',
	'literary_form' => '0',
	'nature_of_content' => '    ',
	'target_audience' => ' ',
);
isa_ok($obj, 'Data::MARC::Field008::Book');

# Test.
eval {
	Data::MARC::Field008::Book->new;
};
is($EVAL_ERROR, "Couldn't create data object of book.\n",
	"Couldn't create data object of book.");
my @errors = err_get;
is(scalar @errors, 11, 'Number of errors (11).');
clean();

# Test.
eval {
	Data::MARC::Field008::Book->new(
		'biography' => 'x',
		'conference_publication' => '0',
		'festschrift' => '0',
		'form_of_item' => 'r',
		'government_publication' => ' ',
		'illustrations' => '    ',
		'index' => '0',
		'literary_form' => '0',
		'nature_of_content' => '    ',
		'raw' => '     r     000 0x',
		'target_audience' => ' ',
	);
};
is($EVAL_ERROR, "Couldn't create data object of book.\n",
	"Couldn't create data object of book.");
@errors = err_get;
is(scalar @errors, 2, 'Number of errors (2).');
is($errors[0]->{'msg'}->[0], "Parameter 'biography' has bad value.",
	"Parameter 'biography' has bad value.");
is($errors[0]->{'msg'}->[1], "Value", "Error key (Value).");
is($errors[0]->{'msg'}->[2], "x", "Error key value (x).");
is(scalar @{$errors[0]->{'msg'}}, 3, 'Number of error values (3).');
is($errors[1]->{'msg'}->[0], "Couldn't create data object of book.",
	"Couldn't create data object of book.");
is(scalar @{$errors[1]->{'msg'}}, 3, 'Number of error values (3).');
is($errors[1]->{'msg'}->[1], 'Raw string', "Error key (Raw string).");
is($errors[1]->{'msg'}->[2], '     r     000 0x', "Error key value (     r     000 0x).");
clean();

# Test.
$Data::MARC::Field008::Book::STRICT = 0;
$obj = Data::MARC::Field008::Book->new(
	'biography' => 'x',
	'conference_publication' => '0',
	'festschrift' => '0',
	'form_of_item' => 'r',
	'government_publication' => ' ',
	'illustrations' => '    ',
	'index' => '0',
	'literary_form' => '0',
	'nature_of_content' => '    ',
	'target_audience' => ' ',
);
isa_ok($obj, 'Data::MARC::Field008::Book');
@errors = err_get;
is(scalar @errors, 0, 'Number of errors (0).');
clean();
