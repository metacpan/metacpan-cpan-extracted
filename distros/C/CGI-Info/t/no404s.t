#!perl -w

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Pod::No404s';
	if($@) {
		plan(skip_all => 'Test::Pod::No404s required for testing POD');
	} else {
		all_pod_files_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
