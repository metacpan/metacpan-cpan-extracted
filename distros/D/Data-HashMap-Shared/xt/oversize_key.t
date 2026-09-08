use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Every XSUB that converts a string key or value enforces the 1GB ceiling, so
# the uint32_t cast below it cannot truncate: a key of 2**32 + n bytes would
# otherwise compare as its first n bytes and match a different entry.  Reaching
# the croak costs a 1GiB scalar -- about 2.1GB resident -- hence xt, the memory
# floor, and one scalar reused across every variant and call.
#
# The scalar is exactly one byte past SHM_MAX_STR_LEN (2**30 - 1): that length's
# packed form sets bit 30, the inline flag, so a guard drifted by one would
# admit the one length that corrupts the encoding.

sub mem_available_kb {
    open my $fh, '<', '/proc/meminfo' or return undef;
    while (<$fh>) { return $1 if /^MemAvailable:\s+(\d+)\s+kB/ }
    return undef;
}
my $avail = mem_available_kb();
plan skip_all => 'cannot read MemAvailable' unless defined $avail;
plan skip_all => sprintf('needs ~4GB free, MemAvailable is %.1fGB', $avail / 1048576)
    if $avail < 4 * 1048576;

# The key ceiling lives in the four string-KEY variants, the value ceiling in
# the four string-VALUE variants; SS is the only one with both.  Both lists are
# complete: these are ten separate near-duplicate files and only the macro body
# is shared, not the call sites.
my @key_variants = (
    ['Data::HashMap::Shared::SS',   'v'],
    ['Data::HashMap::Shared::SI',   1],
    ['Data::HashMap::Shared::SI16', 1],
    ['Data::HashMap::Shared::SI32', 1],
);
my @val_variants = (
    #  class                        existing key  fresh key  short value
    ['Data::HashMap::Shared::SS',   'short', 'fresh', 'v'],
    ['Data::HashMap::Shared::IS',   1,       2,       'v'],
    ['Data::HashMap::Shared::I16S', 1,       2,       'v'],
    ['Data::HashMap::Shared::I32S', 1,       2,       'v'],
);
for (@key_variants, @val_variants) { my $c = $_->[0]; eval "require $c; 1" or die $@ }

my $dir = tempdir(CLEANUP => 1);
my $big = 'x' x 2**30;
is length($big), 1073741824, 'built a string one byte past the 1GB ceiling';

for my $v (@key_variants) {
    my ($class, $val) = @$v;
    (my $short = $class) =~ s/.*:://;
    my $m = $class->new("$dir/key_$short.shm", 64);
    $m->put('short', $val);

    for my $call (
        ['put',       sub { $m->put($big, $val) }],
        ['get',       sub { $m->get($big) }],
        ['get_multi', sub { $m->get_multi($big) }],
        ['get_multi after a real key', sub { $m->get_multi('short', $big) }],
        ['exists',    sub { $m->exists($big) }],
        ['remove',    sub { $m->remove($big) }],
        # set_multi and remove_multi hand-inline the check instead of calling
        # the macro, which is exactly how get_multi drifted twice.
        ['set_multi',    sub { $m->set_multi($big, $val) }],
        ['remove_multi', sub { $m->remove_multi($big) }],
        # a guard hoisted out of the per-argument loop passes every row above
        ['set_multi after a real pair',   sub { $m->set_multi('short', $val, $big, $val) }],
        ['remove_multi after a real key', sub { $m->remove_multi('nosuch', $big) }],
    ) {
        my ($what, $code) = @$call;
        eval { $code->(); 1 };
        like $@, qr/^key too long \(max 1GB\)/, "$short: $what croaks on a 2**30-byte key";
    }
}

# The three batch XSUBs hand-inline the ceiling separately in each half of
# their `if (h->shard_handles)` split, so the sharded copies are their own
# sites.  One sharded map per variant, reusing the same scalar.
for my $v (@key_variants) {
    my ($class, $val) = @$v;
    (my $short = $class) =~ s/.*:://;
    my $m = $class->new_sharded("$dir/sh_$short", 2, 64);
    $m->put('short', $val);

    for my $call (
        ['get_multi',    sub { $m->get_multi($big) }],
        ['set_multi',    sub { $m->set_multi($big, $val) }],
        ['remove_multi', sub { $m->remove_multi($big) }],
        ['get_multi after a real key',    sub { $m->get_multi('short', $big) }],
        ['set_multi after a real pair',   sub { $m->set_multi('short', $val, $big, $val) }],
        ['remove_multi after a real key', sub { $m->remove_multi('nosuch', $big) }],
    ) {
        my ($what, $code) = @$call;
        eval { $code->(); 1 };
        like $@, qr/^key too long \(max 1GB\)/,
            "$short sharded: $what croaks on a 2**30-byte key";
    }
}

# The value side has the same uint32_t cast under the same ceiling; the scalar
# is already built, so this costs no extra memory.  A TTL map, so the ttl
# setters reach their value check whatever order their guards run in.
for my $v (@val_variants) {
    my ($class, $k0, $k1, $val) = @$v;
    (my $short = $class) =~ s/.*:://;
    my $m = $class->new("$dir/val_$short.shm", 64, 0, 60);
    $m->put($k0, $val);
    my $sh = $class->new_sharded("$dir/shval_$short", 2, 64, 0, 60);
    $sh->put($k0, $val);

    for my $call (
        ['put',        sub { $m->put($k0, $big) },           qr/^value too long \(max 1GB\)/],
        ['put_ttl',    sub { $m->put_ttl($k0, $big, 5) },    qr/^value too long \(max 1GB\)/],
        ['add',        sub { $m->add($k1, $big) },           qr/^value too long \(max 1GB\)/],
        ['add_ttl',    sub { $m->add_ttl($k1, $big, 5) },    qr/^value too long \(max 1GB\)/],
        ['update',     sub { $m->update($k0, $big) },        qr/^value too long \(max 1GB\)/],
        ['update_ttl', sub { $m->update_ttl($k0, $big, 5) }, qr/^value too long \(max 1GB\)/],
        ['get_or_set', sub { $m->get_or_set($k1, $big) },    qr/^value too long \(max 1GB\)/],
        ['swap',       sub { $m->swap($k0, $big) },          qr/^value too long \(max 1GB\)/],
        ['set_multi',  sub { $m->set_multi($k0, $big) },     qr/^value too long \(max 1GB\)/],
        ['set_multi (sharded)', sub { $sh->set_multi($k0, $big) }, qr/^value too long \(max 1GB\)/],
        # a guard hoisted out of the per-pair loop passes every row above
        ['set_multi after a real pair',           sub { $m->set_multi($k0, $val, $k1, $big) },  qr/^value too long \(max 1GB\)/],
        ['set_multi after a real pair (sharded)', sub { $sh->set_multi($k0, $val, $k1, $big) }, qr/^value too long \(max 1GB\)/],
        ['cas expected', sub { $m->cas($k0, $big, $val) },   qr/^expected value too long \(max 1GB\)/],
        ['cas desired',  sub { $m->cas($k0, $val, $big) },   qr/^desired value too long \(max 1GB\)/],
        ['cas_take',   sub { $m->cas_take($k0, $big) },      qr/^expected value too long \(max 1GB\)/],
    ) {
        my ($what, $code, $re) = @$call;
        eval { $code->(); 1 };
        like $@, $re, "$short: $what croaks on a 2**30-byte value";
    }
}

done_testing;
