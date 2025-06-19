use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::MARC::Field008::Utils',
	{ 'also_private' => ['BUILD'] },
	'Data::MARC::Field008::Utils is covered.');
