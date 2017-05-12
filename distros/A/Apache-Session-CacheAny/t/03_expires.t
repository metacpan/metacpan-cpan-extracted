use strict;
use Test::More tests => 1;

use Apache::Session::CacheAny;

my %session;
tie %session, 'Apache::Session::CacheAny', undef, {
    CacheImpl => 'Cache::MemoryCache',
    DefaultExpiresIn => '1 seconds',
};

my $sid = $session{_session_id};
untie %session;

sleep 2;

eval {
    tie %session, 'Apache::Session::CacheAny', $sid, {
	CacheImpl => 'Cache::MemoryCache',
    };
};

ok $@, $@;
