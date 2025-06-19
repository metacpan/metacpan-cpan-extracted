use strict;
use warnings;

use Data::MARC::Field008::Book;
use Test::More 'tests' => 2;
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
is($obj->illustrations, '    ', 'Get book illustration (    ).');
