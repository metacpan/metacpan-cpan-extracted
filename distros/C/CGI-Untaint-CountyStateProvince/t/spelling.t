#!perl -w

use strict;
use warnings;

use Test::More;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval 'use Test::Spelling';
if($@) {
	plan skip_all => 'Test::Spelling required for testing POD spelling';
} else {
	all_pod_files_spelling_ok();
}
