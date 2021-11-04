#!perl -w

use strict;
use warnings;

use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::GreaterVersion';

	plan(skip_all => 'Test::GreaterVersion required for checking versions') if $@;

	Test::GreaterVersion::has_greater_version_than_cpan('CGI::Info');

	done_testing();
} else {
	plan(skip_all => 'Author tests not required for installation');
}
