use strict;
use warnings;

use Data::MARC::Field008::Map;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Field008::Map->new(
	'form_of_item' => ' ',
	'government_publication' => ' ',
	'index' => '|',
	'projection' => 'aa',
	'relief' => 'z   ',
	'special_format_characteristics' => '  ',
	'type_of_cartographic_material' => 'a',
);
is($obj->form_of_item, ' ', 'Get map form of item ( ).');
