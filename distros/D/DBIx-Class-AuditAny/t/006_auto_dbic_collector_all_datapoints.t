# -*- perl -*-

# t/006_auto_dbic_collector_all_datapoints.t - test using all built-in datapoints

use strict;
use warnings;
use Test::More;
use Test::Routine::Util;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

use DBIx::Class::AuditAny::Util::BuiltinDatapoints;

my @all_dp_configs = DBIx::Class::AuditAny::Util::BuiltinDatapoints->all_configs;
my @all_dp_names = map { $_->{name} } @all_dp_configs;

run_tests(
	'Tracking to custom tables via AutoDBIC collector (with defaults)', 
	'Routine::One::ToAutoDBIC' => {
		# override track_params so it uses defaults
		track_params => {
			track_all_sources => 1,
			datapoints => \@all_dp_names
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