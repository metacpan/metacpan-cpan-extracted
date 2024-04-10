# https://raw.githubusercontent.com/libwww-perl/URI/master/xt/dependent-modules.t
#
use strict;
use warnings;

use Test::Needs 'Test::DependentModules';
use Test::DependentModules 'test_modules';
use Test::Most;

my @modules = ('CGI::Lingua');

SKIP: {
	skip '$ENV{AUTHOR_TESTING} not set', scalar @modules
		unless $ENV{'AUTHOR_TESTING'};
	delete $ENV{'AUTHOR_TESTING'};
	test_modules(@modules);
}

done_testing();
