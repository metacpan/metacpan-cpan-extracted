use Test::More tests => 13;
use File::Remove qw(remove);

BEGIN { use_ok('Cache::Swifty') };

# rebuild cache directory
remove \1, 't/cache';
system('swifty t/cache --build 4 8 1024') == 0
    or die 'failed to run swifty';

# constructor
my $m;
eval {
    $m = Cache::Swifty->new({
        dir      => 't/cache',
        lifetime => 10,
	flags    => Cache::Swifty::FLAGS_USE_CHECKSUM,
    });
};
is(ref($m), q{Cache::Swifty}, 'new');

# get set
ok($m->set('hello', 'world'), 'set');
is($m->get('hello'), 'world', 'get');
is($m->get('nonexistent'), undef, 'get undefined');

# get set array
ok($m->set('array', [ 1, 2, 3 ]), 'set array');
is_deeply($m->get('array'), [ 1, 2, 3 ], 'get array');

# get set hash
ok($m->set('hash', { a => 1, b => 2 }), 'set hash');
is_deeply($m->get('hash'), { a => 1, b => 2 }, 'get hash');

# lifetime and expiration using mtime
ok($m->set('hello', 'world'), 'set again for lifetime test');
is($m->lifetime, 10, 'get lifetime set by constructor');
$m->lifetime(1);
is($m->lifetime, 1, 'adjust lifetime');
sleep 2;
is($m->get('hello'), undef, 'should be expired by now');
