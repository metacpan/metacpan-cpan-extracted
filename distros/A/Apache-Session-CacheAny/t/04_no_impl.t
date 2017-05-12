use strict;
use Test::More tests => 1;

use Apache::Session::CacheAny;

diag("This test gives you a warning in cleanup, which is harmless.");

my %session;

eval {
    tie %session, 'Apache::Session::CacheAny', undef, {
	CacheImpl => 'Cache::NoImplementation',
    };
};

ok $@, $@;

