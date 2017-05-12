use Test::More tests => 18;
use File::Remove qw(remove);

BEGIN { use_ok('Cache::Swifty') };

# rebuild cache directory
remove \1, 't/cache';
system('swifty t/cache --build 0 2 1') == 0
    or die 'failed to run swifty';

# constructor
my $m = Cache::Swifty->new({
    dir      => 't/cache',
    lifetime => 3600,
});
is(ref($m), q{Cache::Swifty}, 'new');

# set get
ok($m->set('hello', 'world'), 'set');
is($m->get('hello'), 'world', 'get');

# data that does not fit in header
ok($m->set('hello', '0123456789abcdef'x64), 'set large');
is($m->get('hello'), '0123456789abcdef'x64, 'get large');

# data overflow
ok(! $m->set('hello', '0123456789abcdef'x128), 'set overflow');
is($m->get('hello'), undef, 'get overflow');

# fill the set
for my $i (1..4) {
    ok($m->set($i, $i), "fill set $i");
}
for my $i (1..4) {
    is($m->get($i), $i, "fill get $i");
}

# overflow the set
ok($m->set(5, 5), 'overflow cache-set set');
is((sub {
        my $cnt = 0;
        for my $i (1..5) {
            $cnt++ if (($m->get($i) || '') eq $i);
        }
        $cnt;
    })->(),
   4,
   'overflow cache-set get',
);
