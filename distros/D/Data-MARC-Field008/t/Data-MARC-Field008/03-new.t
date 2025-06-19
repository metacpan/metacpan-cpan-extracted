use strict;
use warnings;

use Data::MARC::Field008;
use Data::MARC::Field008::Book;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Common material.
my $material = Data::MARC::Field008::Book->new(
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

# Test.
my $obj = Data::MARC::Field008->new(
	'cataloging_source' => ' ',
	'date_entered_on_file' => '      ',
	'date1' => '    ',
	'date2' => '    ',
	'language' => 'cze',
	'material' => $material,
	'material_type' => 'book',
	'modified_record' => ' ',
	'place_of_publication' => '   ',
	'type_of_date' => 's',
);
isa_ok($obj, 'Data::MARC::Field008');

# Test.
$obj = Data::MARC::Field008->new(
	'cataloging_source' => ' ',
	'date_entered_on_file' => '      ',
	'date1' => '    ',
	'date2' => '    ',
	'language' => 'cze',
	'material' => $material,
	'material_type' => 'book',
	'modified_record' => ' ',
	'place_of_publication' => '   ',
	'type_of_date' => 'b',
);
isa_ok($obj, 'Data::MARC::Field008');

# Test.
$obj = Data::MARC::Field008->new(
	'cataloging_source' => ' ',
	'date_entered_on_file' => '      ',
	'date1' => '18uu',
	'date2' => '    ',
	'language' => 'cze',
	'material_type' => 'book',
	'modified_record' => ' ',
	'place_of_publication' => '   ',
	'type_of_date' => 's',
);
isa_ok($obj, 'Data::MARC::Field008');

# Test.
eval {
	Data::MARC::Field008->new(
		'cataloging_source' => ' ',
		'date_entered_on_file' => '      ',
		'date1' => '18  ',
		'date2' => '    ',
		'language' => 'cze',
		'material' => $material,
		'material_type' => 'book',
		'modified_record' => ' ',
		'place_of_publication' => '   ',
		'type_of_date' => 's',
	);
};
is($EVAL_ERROR, "Parameter 'date1' has value with space character.\n",
	"Parameter 'date1' has value with space character (18  ).");
clean();

# Test.
eval {
	Data::MARC::Field008->new(
		'cataloging_source' => ' ',
		'date_entered_on_file' => '      ',
		'date1' => '18||',
		'date2' => '    ',
		'language' => 'cze',
		'material' => $material,
		'modified_record' => ' ',
		'place_of_publication' => '   ',
		'material_type' => 'book',
	);
};
is($EVAL_ERROR, "Parameter 'date1' has value with pipe character.\n",
	"Parameter 'date1' has value with pipe character (18||).");
clean();
