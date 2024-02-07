#!/usr/bin/perl -w

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Synopsis';

	if($@) {
		plan(skip_all => 'Test::Synopsis required for testing POD Synopsis');
	} else {
		all_synopsis_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
