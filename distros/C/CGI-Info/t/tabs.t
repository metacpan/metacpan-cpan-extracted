#!/usr/bin/env perl

use strict;
use warnings;
use Test::Needs 'Test::Tabs';
use Test::Most;

BEGIN {
	if($ENV{'AUTHOR_TESTING'}) {
		Test::Tabs->import();
		all_perl_files_ok();
		done_testing();
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}
