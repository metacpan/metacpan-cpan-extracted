use Test::More tests => 130;
use File::Remove qw(remove);

BEGIN { use_ok('Cache::Swifty') };

# rebuild cache directory
remove \1, 't/cache';
system('swifty t/cache --build 0 8 200') == 0
    or die 'failed to run swifty';

# constructor
my $m = Cache::Swifty->new({
    dir      => 't/cache',
    lifetime => 3600,
    flags    => Cache::Swifty::FLAGS_USE_CHECKSUM,
});
is(ref($m), q{Cache::Swifty}, 'new');

# check we can at least store 64keys (since it is 64way)
for my $i (1..64) {
    ok($m->set($i, $i), "fill set $i");
}
for my $i (1..64) {
    is($m->get($i), $i, "fill get $i");
}
