use strict;
use warnings;

use Data::MARC::Field008::ComputerFile;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::ComputerFile->new(
	'form_of_item' => ' ',
	'government_publication' => ' ',
	'target_audience' => ' ',
	'type_of_computer_file' => 'a',
);
is($obj->type_of_computer_file, 'a', 'Get computer file type (a).');
