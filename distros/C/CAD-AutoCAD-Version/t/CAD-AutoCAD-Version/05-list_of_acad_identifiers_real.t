use strict;
use warnings;

use CAD::AutoCAD::Version;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = CAD::AutoCAD::Version->new;
my @ret = $obj->list_of_acad_identifiers_real;
my $right_ret_ar = [
	'MC0.0',
	'AC1.2',
	'AC1.3',
	'AC1.40',
	'AC1.50',
	'AC2.10',
	'AC2.21',
	'AC2.22',
	'AC1001',
	'AC1002',
	'AC1003',
	'AC1004',
	'AC1006',
	'AC1009',
	'AC1012',
	'AC1013',
	'AC1014',
	'AC1015',
	'AC1016',
	'AC1017',
	'AC1018',
	'AC1019',
	'AC1020',
	'AC1021',
	'AC1022',
	'AC1023',
	'AC1024',
	'AC1025',
	'AC1026',
	'AC1027',
	'AC1028',
	'AC1029',
	'AC1030',
	'AC1031',
	'AC1032',
	'AC1033',
	'AC1034',
];
is_deeply(
	\@ret,
	$right_ret_ar,
	'List of AutoCAD identifiers ordered by real AutoCAD releases.',
);
