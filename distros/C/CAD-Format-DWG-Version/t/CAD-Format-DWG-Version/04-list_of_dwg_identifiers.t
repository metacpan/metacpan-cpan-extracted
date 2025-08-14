use strict;
use warnings;

use CAD::Format::DWG::Version;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CAD::Format::DWG::Version->new;
my @ret = $obj->list_of_dwg_identifiers;
is_deeply(
	\@ret,
	[
		'MC0.0',
		'AC1.2',
		'AC1.40',
		'AC1.50',
		'AC2.10',
		'AC1001',
		'AC1002',
		'AC1003',
		'AC1004',
		'AC1006',
		'AC1009',
		'AC1010',
		'AC1011',
		'AC1012',
		'AC1013',
		'AC1014',
		'AC1500',
		'AC1015',
		'AC402a',
		'AC402b',
		'AC1018',
		'AC1021',
		'AC1024',
		'AC1027',
		'AC1032',
		'AC103-4',
	],
	'Get list of DWG versions.',
);
