#!perl -w

use strict;
use warnings;

eval 'use Test::Compile';

if($@) {
	plan(skip_all => 'Test::Compile needed to verify module compiles');
} else {
	my $test = Test::Compile->new();
	$test->all_files_ok();
	$test->done_testing();
}
