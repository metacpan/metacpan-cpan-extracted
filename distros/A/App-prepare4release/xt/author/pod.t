#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Pod;
		Test::Pod->import;
		1;
	} or skip_all 'Test::Pod is required for author tests';
}

all_pod_files_ok();
