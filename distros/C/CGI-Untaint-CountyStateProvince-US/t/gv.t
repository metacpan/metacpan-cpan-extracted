#!perl -w

use strict;
use warnings;

use Test::More;

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::GreaterVersion";

plan skip_all => "Test::GreaterVersion required for checking versions" if $@;

Test::GreaterVersion::has_greater_version_than_cpan('CGI::Untaint::CountyStateProvince::US');

done_testing();
