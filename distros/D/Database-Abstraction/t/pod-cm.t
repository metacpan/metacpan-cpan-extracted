#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

if($ENV{'AUTHOR_TESTING'}) {
	eval 'use Test::Pod::Spelling::CommonMistakes';
	if($@) {
		plan(skip_all => 'Test::Pod::Spelling::CommonMistakes required for testing POD spelling');
	} else {
		all_pod_files_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
