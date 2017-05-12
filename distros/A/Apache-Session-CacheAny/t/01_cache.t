use strict;
use Test::More tests => 6;

use Apache::Session::CacheAny;

my %session;
tie %session, 'Apache::Session::CacheAny', undef, {
    CacheImpl => 'Cache::FileCache',
};

my $sid = $session{_session_id};
like $sid, qr/^[0-9a-f]{32}$/, 'session id length';

ok $session{foo} = 'bar', 'store variable';
ok $session{ref} = [ 'foo', 'bar' ], 'store reference';
untie %session;

tie %session, 'Apache::Session::CacheAny', $sid, {
    CacheImpl => 'Cache::FileCache',
};

is $session{_session_id}, $sid, 'persistent session id';
is $session{foo}, 'bar', 'session variables restored';
ok eq_array($session{ref}, [ 'foo', 'bar' ]), 'reference validity';
