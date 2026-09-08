use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

my @VARIANTS = (
    [ II   => 0, 0 ], [ IS   => 0, 1 ], [ SI   => 1, 0 ], [ SS   => 1, 1 ],
    [ I16  => 0, 0 ], [ I32  => 0, 0 ], [ I16S => 0, 1 ], [ I32S => 0, 1 ],
    [ SI16 => 1, 0 ], [ SI32 => 1, 0 ],
);
require "Data/HashMap/Shared/$_->[0].pm" for @VARIANTS;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

# ---------------------------------------------------------------------------
# get_multi must count as an LRU access, like get()
#
# The non-sharded get_multi reimplements the probe inline and used to skip the
# clock bit that get() sets, so a hot set read only in batches was evicted as if
# never touched -- while the sharded get_multi, which routes through get(), kept
# it.
# ---------------------------------------------------------------------------
sub lru_trial {
    my ($v, $kstr, $vstr, $access, $sharded) = @_;
    my $cls  = "Data::HashMap::Shared::$v";
    my $path = "$dir/lru" . $seq++;
    my $m = $sharded ? $cls->new_sharded($path, 1, 64, 4) : $cls->new($path, 64, 4);
    my $k = $kstr ? sub { "k$_[0]" } : sub { $_[0] };
    my $w = $vstr ? sub { "v$_[0]" } : sub { $_[0] * 10 };
    $m->put($k->($_), $w->($_)) for 1 .. 4;
    $access->($m, $k->(1));
    $m->put($k->(5), $w->(5));
    return defined $m->get($k->(1));
}

for my $v (@VARIANTS) {
    my ($name, $kstr, $vstr) = @$v;
    ok  lru_trial($name, $kstr, $vstr, sub { $_[0]->get($_[1]) }),
        "$name: get() counts as an LRU access";
    ok  lru_trial($name, $kstr, $vstr, sub { $_[0]->get_multi($_[1]) }),
        "$name: get_multi() counts as an LRU access";
    ok  lru_trial($name, $kstr, $vstr, sub { $_[0]->get_multi($_[1]) }, 1),
        "$name: sharded get_multi() counts as an LRU access";
    ok !lru_trial($name, $kstr, $vstr, sub { }),
        "$name: an untouched key is still evicted";
}

# ---------------------------------------------------------------------------
# A path holding an embedded NUL must be refused, not truncated at the NUL.
# ---------------------------------------------------------------------------
{
    my $cls  = 'Data::HashMap::Shared::II';
    my $real = "$dir/nul-real.shm";
    $cls->new($real, 16);

    like  exception(sub { $cls->new("$real\0tail", 16) }),
          qr/embedded NUL/, 'new refuses a NUL in the path';
    like  exception(sub { $cls->new_sharded("$dir/nul-sh\0tail", 2, 16) }),
          qr/embedded NUL/, 'new_sharded refuses a NUL in the path prefix';
    like  exception(sub { $cls->new_readonly("$real\0tail") }),
          qr/embedded NUL/, 'new_readonly refuses a NUL in the path';
    like  exception(sub { $cls->new_memfd("nm\0tail", 16) }),
          qr/embedded NUL/, 'new_memfd refuses a NUL in the name';
    like  exception(sub { $cls->unlink("$real\0tail") }),
          qr/embedded NUL/, 'unlink refuses a NUL in the path';
    ok    -e $real, 'unlink did not act on the truncated path';

    ok    $cls->new("$dir/nul-clean.shm", 16), 'a clean path still works';
    ok    $cls->unlink($real), 'unlink still removes a clean path';
}

# ---------------------------------------------------------------------------
# max_size above the capacity max_entries provides can never evict: the map
# fills up and then refuses every insert, keeping its oldest keys.  It is a
# warning, not an error -- the bound is unreachable rather than impossible, and
# LRU ordering (pop/shift) still works.
# ---------------------------------------------------------------------------
{
    my $cls = 'Data::HashMap::Shared::II';
    my $w = warning(sub { $cls->new("$dir/ms1.shm", 100, 1000) });
    like  $w, qr/max_size 1000 needs all \d+ slots/, 'max_size beyond capacity warns';
    # the one sizing pin; everything below is relative to it
    my ($slots) = $w =~ /needs all (\d+) slots/;
    is    $slots, 256, 'max_entries 100 sizes the table to 256 slots';
    like  warning(sub { $cls->new("$dir/ms2.shm", 100, $slots + 1) }),
          qr/max_size @{[ $slots + 1 ]} needs all/, 'one slot beyond capacity warns';
    # A max_size EQUAL to the slot count is unreachable too: the insert probes
    # for a free slot and fails before it ever reaches the eviction check.
    like  warning(sub { $cls->new("$dir/ms3.shm", 100, $slots) }),
          qr/max_size $slots needs all/, 'max_size exactly at capacity warns';
    is    warning(sub { $cls->new("$dir/ms3b.shm", 100, $slots - 1) }),
          '', 'one slot below capacity is silent';
    is    warning(sub { $cls->new("$dir/ms4.shm", 100, 50) }),
          '', 'max_size below capacity is silent';

    # ... and the warning tracks the behaviour: one slot below capacity evicts,
    # at capacity never does
    my %ev;
    for my $ms ($slots - 1, $slots) {
        my $m = do { no warnings 'misc'; $cls->new("$dir/ev$ms.shm", 100, $ms) };
        $m->put($_, $_) for 1 .. 400;
        $ev{$ms} = $m->stats->{evictions};
    }
    ok  $ev{$slots - 1} > 0, 'max_size below capacity really evicts';
    is  $ev{$slots}, 0,      'max_size at capacity really never evicts';
    is    warning(sub { $cls->new("$dir/ms5.shm", 100) }),
          '', 'no LRU bound is silent';
    like  warning(sub { $cls->new_sharded("$dir/ms6", 4, 100, 1000) }),
          qr/max_size 1000 needs all/, 'new_sharded warns too';
    like  warning(sub { $cls->new_memfd('ms7', 100, 1000) }),
          qr/max_size 1000 needs all/, 'new_memfd warns too';

    my $quiet = do { no warnings 'misc'; warning(sub { $cls->new("$dir/ms8.shm", 100, 1000) }) };
    is $quiet, '', 'the warning is suppressible with "no warnings"';

    # the warning describes the map, not the arguments: attaching ignores them,
    # so a sound file must stay silent however silly the arguments are, and an
    # unsound one must speak up even when the arguments look fine.
    my $good = "$dir/ms-good.shm";
    $cls->new($good, 100, 50);
    is    warning(sub { $cls->new($good, 100, 1000) }),
          '', 'attaching to a sound file with silly arguments is silent';
    my $bad = "$dir/ms-bad.shm";
    do { no warnings 'misc'; $cls->new($bad, 100, 1000) };
    like  warning(sub { $cls->new($bad, 100, 50) }),
          qr/max_size 1000 needs all/, 'attaching to an unsound file warns';

    my $frozen = "$dir/ms-frozen.shm";
    do { no warnings 'misc'; $cls->new($frozen, 100, 1000)->freeze };
    is    warning(sub { $cls->new_readonly($frozen) }),
          '', 'a frozen map cannot insert, so new_readonly stays silent';

    # it really is only a warning: the map is usable, with LRU ordering intact
    my $m = do { no warnings 'misc'; $cls->new("$dir/ms9.shm", 100, 1000) };
    $m->put($_, $_) for 1 .. 5;
    my ($k) = $m->pop;
    is $k, 1, 'the map still works, oldest-first, after the warning';
}

sub exception { my $c = shift; my $ok = eval { $c->(); 1 }; return $ok ? '' : ($@ || 'died') }
sub warning   { my $c = shift; my $w = ''; local $SIG{__WARN__} = sub { $w .= $_[0] }; $c->(); return $w }

done_testing;
