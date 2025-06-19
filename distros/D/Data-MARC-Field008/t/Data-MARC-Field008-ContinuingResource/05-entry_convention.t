use strict;
use warnings;

use Data::MARC::Field008::ContinuingResource;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
## cnb003684882
my $obj = Data::MARC::Field008::ContinuingResource->new(
	'conference_publication' => '0',
	'entry_convention' => '2',
	'form_of_item' => 'o',
	'form_of_original_item' => ' ',
	'frequency' => ' ',
	'government_publication' => ' ',
	'nature_of_content' => '   ',
	'nature_of_entire_work' => ' ',
	'original_alphabet_or_script_of_title' => 'b',
	'regularity' => 'x',
	'type_of_continuing_resource' => 'w',
);
is($obj->entry_convention, 2, 'Get entry convention (2).');
