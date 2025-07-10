use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::OFN::Common::TimeMoment',
	{ 'also_private' => ['BUILD'] },
	'Data::OFN::Common::TimeMoment is covered.');
