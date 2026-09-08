use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Error paths no other test reaches; one of them, the destroyed-handle check in
# unlink, segfaults without its guard.  Each croaking path is pinned by its
# message, because with a guard gone a later check often still croaks in
# different words; the two that return silently are pinned by the object
# surviving.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }

sub poke {
    my ($f, $off, $fmt, $v) = @_;
    open my $h, '+<', $f or die $!;
    sysseek($h, $off, 0);
    syswrite($h, pack($fmt, $v));
    close $h;
}

# ---- 1. max/min/decr croak when a NEW key cannot be inserted (full table) ----
{
    my $m = Data::HashMap::Shared::II->new(path('full'), 2);
    my $n = 0;
    $n++ while $n < 10_000 && $m->put($n, $n);
    ok $n > 0 && $n < 10_000, "map filled to capacity at $n entries";
    is $m->max(0, 5), 5, 'max on an existing key works at capacity';
    ok !eval { $m->max(999_999, 5); 1 }, 'max on a new key croaks when the map is full';
    like $@, qr/\bmax failed\b/, '  ...naming the failed operation';
    ok !eval { $m->min(888_888, 5); 1 }, 'min on a new key croaks when full';
    like $@, qr/\bmin failed\b/, '  ...naming the failed operation';
    ok !eval { $m->decr(777_777); 1 }, 'decr on a new key croaks when full';
    like $@, qr/\bdecrement failed\b/, '  ...naming the failed operation';
}

# ---- 2. class-method unlink: arity and destroyed-handle guards ----
{
    ok !eval { Data::HashMap::Shared::II->unlink(); 1 }, 'unlink with no path croaks';
    like $@, qr/^Usage: Data::HashMap::Shared::II->unlink\(\$path\)/, '  ...with a usage message';

    # in a child: without the guard this dereferences the freed handle and
    # takes the whole harness down with SIGSEGV rather than failing one test
    my $p = path('u');
    my $st = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $m = Data::HashMap::Shared::II->new($p, 16);
            $m->DESTROY;
            eval { $m->unlink; 1 } and POSIX::_exit(20);
            POSIX::_exit($@ =~ /^Attempted to use a destroyed Data::HashMap::Shared::II object/ ? 0 : 21);
        }
        waitpid $pid, 0; $?;
    };
    is $st, 0, 'unlink on an explicitly destroyed handle croaks, naming the object'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    ok(Data::HashMap::Shared::II->unlink($p), 'class-form unlink removes the file');
}

# ---- 3. DESTROY refuses a foreign invocant (t/45 covers put/get/size only) ----
# Without the class check, II::DESTROY on an SS handle closes that map and
# zeroes its IV, and II::Cursor::DESTROY frees an SS cursor: the object is
# destroyed from under its owner.  Neither crashes -- the zeroed IV makes the
# next call croak -- so the oracle is that the victim is still usable.  Run in
# a child anyway, so a regression that does crash fails one test instead of
# killing the harness.
{
    my $st = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $ss = Data::HashMap::Shared::SS->new(path('foreign'), 64);
            $ss->put('k', 'v');
            eval { Data::HashMap::Shared::II::DESTROY($ss); 1 } or POSIX::_exit(22);
            POSIX::_exit((eval { $ss->size } // -1) == 1 ? 0 : 20);
        }
        waitpid $pid, 0; $?;
    };
    is $st, 0, 'II::DESTROY on an SS map leaves that map alive'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);

    my $cst = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $ss = Data::HashMap::Shared::SS->new(path('foreign_c'), 64);
            $ss->put('k', 'v');
            my $c = $ss->cursor;
            eval { Data::HashMap::Shared::II::Cursor::DESTROY($c); 1 } or POSIX::_exit(23);
            my @kv = eval { $c->next };
            POSIX::_exit(@kv == 2 && $kv[0] eq 'k' ? 0 : 21);
        }
        waitpid $pid, 0; $?;
    };
    is $cst, 0, 'II::Cursor::DESTROY on an SS cursor leaves that cursor alive'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $cst, $cst & 127, $cst >> 8);
}

# ---- 4. the five CK_U32 arguments no other test reaches ----
# (max_entries is t/27's, ttl and flush_expired_partial's limit are t/14's;
#  drain's limit needs no CK_U32 -- it is clamped in UV space before the cast)
{
    my @cases = (
        ['lru_max',     sub { Data::HashMap::Shared::II->new(undef, 64, 2**32) }],
        ['ttl_default', sub { Data::HashMap::Shared::II->new(undef, 64, 0, 2**32) }],
        ['lru_skip',    sub { Data::HashMap::Shared::II->new(undef, 64, 0, 0, 2**32) }],
        ['num_shards',  sub { Data::HashMap::Shared::II->new_sharded(path('s'), 2**32, 64) }],
    );
    for my $c (@cases) {
        my ($what, $run) = @$c;
        ok !eval { $run->(); 1 }, "new: $what of 2**32 is refused, not truncated";
        like $@, qr/\Q$what\E 4294967296 exceeds the maximum of 4294967295/,
            "  ...naming $what and the limit";
    }
    my $m = Data::HashMap::Shared::II->new(path('r'), 64);
    ok !eval { $m->reserve(2**32); 1 }, 'reserve: target of 2**32 is refused';
    like $@, qr/target 4294967296 exceeds the maximum of 4294967295/, '  ...naming target';
}

# ---- 5. size guards on the two open paths ----
{
    my $p = path('tiny');
    open my $fh, '>', $p or die $!; print $fh 'abc'; close $fh;
    ok !eval { Data::HashMap::Shared::II->new($p, 64); 1 }, 'new on a short file is refused';
    like $@, qr/file too small \(3 bytes, need \d+\)/, '  ...reporting both sizes';
    ok !eval { Data::HashMap::Shared::II->new_readonly($p); 1 },
        'new_readonly on a short file is refused';
    like $@, qr/file too small for header/, '  ...saying the header does not fit';
}

# ---- 6. shard path length guard ----
{
    ok !eval { Data::HashMap::Shared::II->new_sharded('x' x 5000, 2, 16); 1 },
        'new_sharded refuses a prefix that overflows the shard path buffer';
    like $@, qr/shard path too long/, '  ...saying so';
}

# ---- 7. corrupt layout offsets are refused on attach ----
{
    my $p = path('lay');
    { my $m = Data::HashMap::Shared::II->new($p, 1024); $m->put(1, 2); }
    poke($p, 24, 'L', 8);                    # max_size: LRU arrays the file has no room for
    ok !eval { Data::HashMap::Shared::II->new($p, 1024); 1 },
        'attach refuses a header whose LRU/TTL arrays do not fit';
    like $@, qr/file too small for LRU\/TTL arrays/, '  ...naming the region';

    my $q = path('lay2');
    { my $m = Data::HashMap::Shared::II->new($q, 1024); $m->put(1, 2); }
    poke($q, 80, 'Q', 0);                    # reader_slots_off = 0
    ok !eval { Data::HashMap::Shared::II->new($q, 1024); 1 },
        'attach refuses a header with no reader_slots region';
    like $@, qr/reader_slots region missing or out of bounds/, '  ...naming the region';
}

# ---- 8. a frozen file whose lock word names a LIVE writer ----
{
    my $p = path('froz');
    { my $m = Data::HashMap::Shared::II->new($p, 64); $m->put(1, 2); $m->freeze }
    poke($p, 128, 'L', 0x80000000 | $$);     # wlock held by us -- a live pid
    ok !eval { Data::HashMap::Shared::II->new_readonly($p); 1 },
        'new_readonly refuses a frozen file with a write in flight';
    like $@, qr/a write is still in flight on this frozen file \(pid $$\); retry/,
        '  ...naming the live holder, not a crashed writer';
}

done_testing;
