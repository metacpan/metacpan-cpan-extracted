#!perl -w

use strict;
use warnings;

use Test::Most;
use Test::Needs 'Test::Strict';

if($ENV{'AUTHOR_TESTING'}) {
	Test::Strict->import();
	all_perl_files_ok();
	all_cover_ok(80);	# at least 80% coverage
} else {
	plan(skip_all => 'Author tests not required for installation');
}
