# https://raw.githubusercontent.com/libwww-perl/URI/master/xt/dependent-modules.t
#
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::DependentModules';
use Test::DependentModules 'test_modules';
use Test::Most;

my @modules = ('CGI::Lingua');

SKIP: {
	delete $ENV{'AUTHOR_TESTING'};
	Test::DependentModules->import();
	test_modules(@modules);
}

done_testing();
