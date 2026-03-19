use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

# clear mid-iteration resets iterator state
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, $_, $_ * 10 for 1..20;

    # start iterating
    my ($k, $v) = shm_ii_each $map;
    ok(defined $k, 'each returns entry before clear');

    # clear mid-iteration
    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'size is 0 after clear');

    # each should return nothing (iterator was reset by clear)
    ($k, $v) = shm_ii_each $map;
    ok(!defined $k, 'each returns nothing after clear on empty map');

    # re-populate and iterate from beginning
    shm_ii_put $map, 100, 200;
    ($k, $v) = shm_ii_each $map;
    ok(defined $k, 'each works after clear + re-populate');
    is($k, 100, 'each returns correct key after clear');
    is($v, 200, 'each returns correct value after clear');

    unlink $path;
}

# clear with live cursor doesn't corrupt iterator count
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, $_, $_ * 10 for 1..20;

    my $cur = shm_ii_cursor $map;
    shm_ii_cursor_next $cur;  # cursor is active

    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'size 0 after clear with live cursor');

    undef $cur;  # destroy cursor — must not underflow iterating count

    # map should still function properly (grow/shrink not permanently deferred)
    shm_ii_put $map, $_, $_ for 1..100;
    is(shm_ii_size $map, 100, 'map functional after clear-with-cursor + destroy');

    # capacity should have grown (not stuck at initial due to deferred)
    ok(shm_ii_capacity($map) > 16, 'table grew after cursor destroy');

    unlink $path;
}

# put returns false when table is full at max_table_cap
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 4);
    my $max = shm_ii_max_entries $map;

    my $inserted = 0;
    for my $i (1..($max * 2)) {
        my $ok = shm_ii_put $map, $i, $i * 10;
        if ($ok) {
            $inserted++;
        } else {
            last;
        }
    }
    my $cap = shm_ii_capacity $map;
    ok($inserted > 0 && $inserted < $max * 2,
        "inserted $inserted entries before full (max_entries=$max, cap=$cap)");

    # verify existing entries are intact
    for my $i (1..$inserted) {
        is($map->get($i), $i * 10, "entry $i still readable after full");
    }

    unlink $path;
}

# get_or_set string: mutating returned SV doesn't affect shared value
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    my $default = "hello";
    my $got = shm_ss_get_or_set $map, "key1", $default;
    is($got, "hello", 'get_or_set returns default on insert');

    # mutate the returned value
    $got .= " world";
    is($got, "hello world", 'local mutation works');

    # shared value should be unchanged
    my $stored = shm_ss_get $map, "key1";
    is($stored, "hello", 'shared value unchanged after mutating returned SV');

    # second call should return existing value (also a copy)
    my $got2 = shm_ss_get_or_set $map, "key1", "other";
    is($got2, "hello", 'get_or_set returns existing value on second call');

    unlink $path;
}

# put_ttl with ttl_sec=0 creates permanent entry on TTL-enabled map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put_ttl $map, 1, 100, 0;  # permanent
    shm_ii_put $map, 2, 200;         # default TTL (2s)

    my $rem1 = shm_ii_ttl_remaining $map, 1;
    is($rem1, 0, 'ttl_remaining is 0 for permanent entry');

    my $rem2 = shm_ii_ttl_remaining $map, 2;
    ok(defined $rem2 && $rem2 > 0, 'ttl_remaining > 0 for TTL entry');

    sleep 3;

    # permanent entry survives
    my $v1 = shm_ii_get $map, 1;
    is($v1, 100, 'permanent entry (ttl=0) survives past default TTL');

    # TTL entry expired
    my $v2 = shm_ii_get $map, 2;
    ok(!defined $v2, 'default TTL entry expired');

    unlink $path;
}

# stale write lock recovery: simulate dead process holding wrlock
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 42;

    # Simulate a stale lock by forking a child that sets the lock and dies
    my $pid = fork();
    if ($pid == 0) {
        my $child_map = Data::HashMap::Shared::II->new($path, 1000);
        # Do a normal put to prove the child can access the map
        shm_ii_put $child_map, 2, 99;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    # Now manually corrupt the lock to simulate the child dying while holding it.
    # The header is at the start of the mmap file. rwlock is at offset 128
    # and encodes 0x80000000 | pid when write-locked. seq is at offset 64.
    open my $fh, '+<:raw', $path or die "Cannot open $path: $!";
    # Set rwlock = 0x80000000 | $pid (write-locked by dead child)
    seek($fh, 128, 0);
    print $fh pack('V', 0x80000000 | $pid);
    # Set seq to odd (writer active)
    seek($fh, 64, 0);
    print $fh pack('V', 1);
    close $fh;

    # Re-open the map — the stale lock is now in the mmap
    undef $map;
    $map = Data::HashMap::Shared::II->new($path, 1000);

    # This should recover after SHM_LOCK_TIMEOUT_SEC (2s) since $pid is dead
    my $val = shm_ii_get $map, 1;
    # The data written before corruption should still be readable
    is($val, 42, 'recovered from stale lock without deadlock');
    ok(shm_ii_stat_recoveries($map) > 0, 'stat_recoveries incremented after recovery');

    unlink $path;
}

# error diagnostics: wrong variant gives informative message
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    shm_ii_put $map, 1, 1;
    undef $map;

    eval { Data::HashMap::Shared::SS->new($path, 100) };
    like($@, qr/variant mismatch/, 'variant mismatch gives diagnostic error');
    like($@, qr/file=\d+, expected=\d+/, 'error includes variant IDs');

    unlink $path;
}

# error diagnostics: bad path gives errno message
{
    eval { Data::HashMap::Shared::II->new('/nonexistent/path/test.shm', 100) };
    like($@, qr/No such file|Permission denied/, 'bad path gives errno in error');
}

# unlink: instance method
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    shm_ii_put $map, 1, 42;
    ok(-f $path, 'backing file exists');
    ok($map->unlink, 'instance unlink returns true');
    ok(!-f $path, 'backing file removed after unlink');
    # map still works (mmap stays alive after unlink)
    my $v = shm_ii_get $map, 1;
    is($v, 42, 'map still readable after unlink');
}

# unlink: class method
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    undef $map;
    ok(-f $path, 'backing file exists before class unlink');
    ok(Data::HashMap::Shared::II->unlink($path), 'class unlink returns true');
    ok(!-f $path, 'backing file removed after class unlink');
}

# unlink: returns false for non-existent file
{
    ok(!Data::HashMap::Shared::II->unlink('/tmp/nonexistent_shm_test_' . $$ . '.shm'),
       'unlink returns false for non-existent file');
}

done_testing;
