#!/usr/bin/perl -wT

use strict;
use warnings;
use Test::Most;

# if($ENV{AUTHOR_TESTING}) {
	# eval 'use Test::CPAN::Changes';
	# plan(skip_all => 'Test::CPAN::Changes required for this test') if $@;
	# changes_ok();
# } else {
	# plan(skip_all => 'Author tests not required for installation');
# }

plan(skip_all => "I don't agree with the author's format for dates");
