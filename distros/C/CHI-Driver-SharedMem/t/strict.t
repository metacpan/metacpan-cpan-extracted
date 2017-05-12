#!perl -w

use strict;
use warnings;

use Test::Most;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval 'use Test::Strict';
if($@) {
	plan skip_all => 'Test::Strict required for testing use strict';
} else {
	all_perl_files_ok();
	warnings_ok('lib/CHI/Driver/SharedMem.pm');
}
