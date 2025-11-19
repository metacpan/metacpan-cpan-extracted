use strict;
use warnings;

use Data::MARC::Field008::ComputerFile;
use English;
use Error::Pure::Utils qw(clean err_get);
use Test::More 'tests' => 16;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::ComputerFile->new(
	'form_of_item' => ' ',
	'government_publication' => ' ',
	'target_audience' => ' ',
	'type_of_computer_file' => 'a',
);
isa_ok($obj, 'Data::MARC::Field008::ComputerFile');

# Test.
eval {
	Data::MARC::Field008::ComputerFile->new;
};
is($EVAL_ERROR, "Couldn't create data object of computer file.\n",
	"Couldn't create data object of computer file.");
my @errors = err_get;
is(scalar @errors, 5, 'Number of errors (5).');
clean();

# Test.
eval {
	Data::MARC::Field008::ComputerFile->new(
		'form_of_item' => 'x',
		'government_publication' => ' ',
		'raw' => '     x  a        ',
		'target_audience' => ' ',
		'type_of_computer_file' => 'a',
	);
};
is($EVAL_ERROR, "Couldn't create data object of computer file.\n",
	"Couldn't create data object of computer file.");
@errors = err_get;
is(scalar @errors, 2, 'Number of errors (2).');
is($errors[0]->{'msg'}->[0], "Parameter 'form_of_item' has bad value.",
	"Parameter 'form_of_item' has bad value.");
is($errors[0]->{'msg'}->[1], "Value", "Error key (Value).");
is($errors[0]->{'msg'}->[2], "x", "Error key value (x).");
is(scalar @{$errors[0]->{'msg'}}, 3, 'Number of error values (3).');
is($errors[1]->{'msg'}->[0], "Couldn't create data object of computer file.",
	"Couldn't create data object of computer file.");
is(scalar @{$errors[1]->{'msg'}}, 3, 'Number of error values (3).');
is($errors[1]->{'msg'}->[1], 'Raw string', "Error key (Raw string).");
is($errors[1]->{'msg'}->[2], '     x  a        ', "Error key value (     x  a        ).");
clean();

# Test.
$Data::MARC::Field008::ComputerFile::STRICT = 0;
$obj = Data::MARC::Field008::ComputerFile->new(
	'form_of_item' => 'x',
	'government_publication' => ' ',
	'raw' => '     x  a        ',
	'target_audience' => ' ',
	'type_of_computer_file' => 'a',
);
isa_ok($obj, 'Data::MARC::Field008::ComputerFile');
@errors = err_get;
is(scalar @errors, 0, 'Number of errors (0).');
