# -*- perl -*-

# t/005_auto_dbic_collector_defaults.t - test using mostly defaults

use strict;
use warnings;
use Test::More;
use Test::Routine::Util;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;



run_tests(
	'Tracking to custom tables via AutoDBIC collector (with defaults)', 
	'Routine::One::ToAutoDBIC' => {
		# override track_params so it uses defaults
		track_params => {
			track_all_sources => 1,
		},
		# These are actually the defaults
		colnames => {
			old		=> 'old_value',
			new		=> 'new_value',
			column	=> 'column_name'
		}
	}
);

done_testing;