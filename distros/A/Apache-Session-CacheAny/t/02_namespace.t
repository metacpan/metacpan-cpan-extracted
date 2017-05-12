use strict;
use Test::More tests => 1;

use Apache::Session::CacheAny;

my %session;
tie %session, 'Apache::Session::CacheAny', undef, {
    CacheImpl => 'Cache::MemoryCache',
    Namespace => 'Apache::Session::CacheAny',
};

my $sid = $session{_session_id};
untie %session;

eval {
    tie %session, 'Apache::Session::CacheAny', $sid, {
	CacheImpl => 'Cache::MemoryCache',
	Namespace => 'Another Namespace',
    };
};
ok $@, $@;
