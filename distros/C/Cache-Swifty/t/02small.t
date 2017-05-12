use Test::More tests => 35;
use File::Remove qw(remove);

BEGIN { use_ok('Cache::Swifty') };

# rebuild cache directory
remove \1, 't/cache';
system('swifty t/cache --build 0 2 16') == 0
    or die 'failed to run swifty';

# constructor
my $m = Cache::Swifty->new({
    dir      => 't/cache',
    lifetime => 3600,
    flags    => Cache::Swifty::FLAGS_USE_CHECKSUM,
});
is(ref($m), q{Cache::Swifty}, 'new');

sub rep {
    my ($src, $len) = @_;
    substr $src x $len, 0, $len;
}

# fill 5kbs
for my $i (1..16) {
    ok($m->set($i, rep($i, 5120)), "fill set 5kb $i");
    is($m->get($i), rep($i, 5120), "fill get 5kb $i");
}
# check we can read only three
is((sub {
        my $cnt = 0;
        for my $i (1..16) {
            $cnt++ if (($m->get($i) || '') eq rep($i, 5120));
        }
        $cnt;
    })->(),
   3,
   'fill check stored',
);
