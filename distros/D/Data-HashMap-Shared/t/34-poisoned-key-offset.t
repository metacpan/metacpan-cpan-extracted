use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

# Every path that compares an arena key must bound key_off before memcmp
# (CWE-125): the lock-free get() and exists() inline their own compare, and the
# write-locked paths share _key_eq_str.  A record whose key_off points outside
# the arena must be a miss in all of them, not a crash.
#
# Each op runs in a forked child so a regression is a failed test, not a dead
# harness.

my $dir = tempdir(CLEANUP => 1);
my $KEY = 'a-key-well-over-the-inline-limit';

my @variants = (
    { class => 'Data::HashMap::Shared::SS',   val => 'value' },
    { class => 'Data::HashMap::Shared::SI',   val => 42 },
    { class => 'Data::HashMap::Shared::SI16', val => 7 },
    { class => 'Data::HashMap::Shared::SI32', val => 4242 },
);

for my $v (@variants) {
    my ($class, $val) = @$v{qw(class val)};
    (my $short = $class) =~ s/.*:://;
    my $path = "$dir/poisoned-$short.hm";

    eval "require $class" or BAIL_OUT("cannot load $class: $@");
    { my $m = $class->new($path, 64); $m->put($KEY, $val); $m->sync }

    # Point the live record's key_off outside the arena.
    {
        open my $f, '+<:raw', $path or die $!;
        my $d = do { local $/; <$f> };
        my ($node_size)  = unpack 'L', substr($d, 12, 4);
        my ($cap)        = unpack 'L', substr($d, 20, 4);
        my ($nodes_off)  = unpack 'Q', substr($d, 40, 8);
        my ($states_off) = unpack 'Q', substr($d, 48, 8);
        my ($arena_cap)  = unpack 'Q', substr($d, 72, 8);

        my $slot;
        for my $i (0 .. $cap - 1) {
            $slot = $i, last if unpack('C', substr($d, $states_off + $i, 1)) >= 2;
        }
        ok(defined $slot, "$short: located the live slot to poison")
            or BAIL_OUT('no live slot');

        seek $f, $nodes_off + $slot * $node_size, 0 or die $!;  # key_off is at +0
        print $f pack 'L', $arena_cap + 0x10000000;
        close $f or die $!;
    }

    # The poke must have hit the key's metadata: the record is now unreachable.
    {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $m = $class->new($path, 64);
            POSIX::_exit(defined $m->get($KEY) ? 1 : 0);
        }
        waitpid $pid, 0;
        is($?, 0, "$short: get() no longer finds the poisoned record");
    }

    # get/exists are the lock-free readers the 0.19 fix covered; the rest reach
    # the poisoned record through the shared compare under the write lock.
    for my $op (qw(get exists remove put take update)) {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $m = $class->new($path, 64);
            $m->get($KEY)          if $op eq 'get';
            $m->exists($KEY)       if $op eq 'exists';
            $m->remove($KEY)       if $op eq 'remove';
            $m->put($KEY, $val)    if $op eq 'put';
            $m->take($KEY)         if $op eq 'take';
            $m->update($KEY, $val) if $op eq 'update';
            POSIX::_exit(0);
        }
        waitpid $pid, 0;
        is($? & 127, 0, "$short: $op() survives a key_off outside the arena")
            or diag sprintf('child died on signal %d', $? & 127);
    }
}


# The block above only reaches the paths that find a key by comparing it.
# keys() and to_hash() read the key through shm_str_ptr instead, which carries a
# bound of its own (each, cursor and drain copy it through shm_str_copy, bounded
# the same way), and nothing had exercised either against a poisoned record.
#
# A near-boundary offset was tried here first and is not worth testing: mmap
# rounds the mapping up to a page, so a key running a few bytes past arena_cap
# still lands in mapped memory and yields garbage rather than a fault.
{
    my $dir3 = tempdir(CLEANUP => 1);
    my $path = "$dir3/far.hm";
    my $KEY2 = 'a-key-well-over-the-inline-limit';
    { my $m = Data::HashMap::Shared::SS->new($path, 64); $m->put($KEY2, 'value'); $m->sync }

    open my $f2, '+<:raw', $path or die $!;
    my $d = do { local $/; <$f2> };
    my ($node_size)  = unpack 'L', substr($d, 12, 4);
    my ($cap)        = unpack 'L', substr($d, 20, 4);
    my ($nodes_off)  = unpack 'Q', substr($d, 40, 8);
    my ($states_off) = unpack 'Q', substr($d, 48, 8);
    my ($arena_cap)  = unpack 'Q', substr($d, 72, 8);
    my $slot;
    for my $i (0 .. $cap - 1) {
        $slot = $i, last if unpack('C', substr($d, $states_off + $i, 1)) >= 2;
    }
    ok defined $slot, 'iteration paths: located the live slot';
    my $far = $arena_cap + 0x10000000;
    seek $f2, $nodes_off + $slot * $node_size, 0 or die $!;
    print $f2 pack 'L', $far;
    close $f2 or die $!;

    for my $op (qw(get exists remove keys values each cursor to_hash drain)) {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $m = Data::HashMap::Shared::SS->new($path, 64);
            if    ($op eq 'get')     { $m->get($KEY2) }
            elsif ($op eq 'exists')  { $m->exists($KEY2) }
            elsif ($op eq 'remove')  { $m->remove($KEY2) }
            elsif ($op eq 'keys')    { my @k = $m->keys }
            elsif ($op eq 'values')  { my @v = $m->values }
            elsif ($op eq 'each')    { while (my ($k, $v) = $m->each) { } }
            elsif ($op eq 'cursor')  { my $c = $m->cursor; while (my ($k, $v) = $c->next) { } }
            elsif ($op eq 'to_hash') { my $h = $m->to_hash }
            elsif ($op eq 'drain')   { my @d = $m->drain(10) }
            POSIX::_exit(0);
        }
        waitpid $pid, 0;
        is($? & 127, 0, "$op() survives a poisoned key_off")
            or diag sprintf('child died on signal %d', $? & 127);
    }
}

# The boundary value the far poison cannot reach.  Every arena bound is
# `off + len > arena_cap`; a block that ends exactly at arena_cap is legitimate
# and must be readable through every reader.  An off-by-one (>=) reports it
# absent or empty and passes the rest of the suite.  Verified: a build with all
# seven bounds flipped fails every read assertion below (14 of 19; the sizing
# ones are write-path facts a read bound cannot touch); the clean build passes.
{
    my $dir3 = tempdir(CLEANUP => 1);
    # bump allocation from offset 16 in power-of-two classes: 30 x 4096 + 255 x 16
    # + one final 4096-byte block fills a 131072-byte arena to the last byte
    my $fill = sub {
        my $m = shift;
        $m->put("k$_", 'V' x 4096) for 1 .. 30;                # inline keys, 4096-byte values
        $m->put(sprintf('key%05d', $_), 'x') for 1 .. 255;     # 8-byte keys -> 16-byte blocks
        is $m->arena_used, $m->arena_cap - 4096, 'arena filled to one block short of arena_cap'
            or die 'the arena fill no longer lands one block short of arena_cap';
    };
    {   # the last block is a value
        my $m = Data::HashMap::Shared::SS->new("$dir3/edge-val.hm", 1024, 0, 3600);
        $fill->($m);
        my $want = 'L' x 4096;
        ok $m->put('last', $want), 'a value block ending exactly at arena_cap is accepted';
        is $m->arena_used, $m->arena_cap, '  ...and the arena is now full to the byte';
        is $m->get('last'), $want, 'get() reads a value ending at arena_cap';
        is +(($m->get_multi('last'))[0]), $want, 'get_multi() reads it';
        is +(($m->get_with_ttl('last'))[0]), $want, 'get_with_ttl() reads it';
        is $m->to_hash->{last}, $want, 'to_hash() reads it';
        is scalar(grep { $_ eq $want } $m->values), 1, 'values() reads it';
        my %e; while (my ($k, $v) = $m->each) { $e{$k} = $v }
        is $e{last}, $want, 'each() reads it';
    }
    {   # the last block is a key
        my $m = Data::HashMap::Shared::SS->new("$dir3/edge-key.hm", 1024, 0, 3600);
        $fill->($m);
        my $K = 'K' x 4096;
        ok $m->put($K, 'v'), 'a key block ending exactly at arena_cap is accepted';
        is $m->get($K), 'v', 'get() finds a key ending at arena_cap';
        ok $m->exists($K), 'exists() finds it';
        ok defined $m->ttl_remaining($K), 'ttl_remaining() finds it';
        is +(($m->get_multi($K))[0]), 'v', 'get_multi() finds it';
        is +(($m->get_with_ttl($K))[0]), 'v', 'get_with_ttl() finds it';
        is scalar(grep { $_ eq $K } $m->keys), 1, 'keys() reads it';
        ok exists $m->to_hash->{$K}, 'to_hash() reads it';
        my %e; while (my ($k, $v) = $m->each) { $e{$k} = $v }
        ok exists $e{$K}, 'each() reads it';
    }
}

done_testing;
