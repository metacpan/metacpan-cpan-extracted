use Test::More tests => 10;
use File::Remove qw(remove);

BEGIN { use_ok('Cache::Swifty') };

# rebuild cache directory
remove \1, 't/cache';
system('swifty t/cache --build 0 4 100') == 0
    or die 'failed to run swifty';

# constructor
my $m = Cache::Swifty->new({
    dir      => 't/cache',
    lifetime => 6,
    flags    => Cache::Swifty::FLAGS_USE_CHECKSUM,
});
is(ref($m), q{Cache::Swifty}, 'new');

# accessor
is($m->refresh_before, 0, 'default refresh_before');
$m->refresh_before(3);
is($m->refresh_before, 3, 'update refresh_before');
ok(! $m->do_refresh, 'do_refresh flag should be until first get');

$m->get('hoge');
ok(! $m->do_refresh, 'do_refresh should return off when not found');

$m->set('hello', 'world');
$m->get('hello');
ok(! $m->do_refresh, 'do_refresh off when refresh_before<lifetime');
sleep(4);
$m->get('hello');
ok($m->do_refresh, 'do_refresh on for first lifetime<refersh_before');
$m->get('hello');
ok(! $m->do_refresh, 'do_refresh off for consecutive calls');
sleep(3);
$m->get('hello');
ok(! $m->do_refresh, 'do_refresh off after expiration');
