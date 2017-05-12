# -*- perl -*-

# t/002_record_custom_tables.t - test logging changes to existing/custom tables

use strict;
use warnings;
use Test::More;
use Test::Routine::Util;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

run_tests(
	'Tracking to custom tables via DBIC collector', 
	'Routine::One::ToCustTables'
);

run_tests(
	'Tracking to custom tables via DBIC collector to different schema',
	'Routine::One::ToCustTables' => {
		record_different_schema => 1
	}
);

done_testing;
