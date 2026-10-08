use strict;
use warnings;
use Test::More;
use Time::HiRes ();

plan skip_all => "AUTHOR_TESTING not set" unless $ENV{AUTHOR_TESTING};
use File::Temp ();
use File::Spec ();

use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

# The croaks carry strerror in the process's locale; the matches below are English.
POSIX::setlocale(POSIX::LC_ALL(), 'C');

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, $_, $_ * 10 for 1..20;

    my ($k, $v) = shm_ii_each $map;
    ok(defined $k, 'each returns entry before clear');

    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'size is 0 after clear');

    ($k, $v) = shm_ii_each $map;
    ok(!defined $k, 'each returns nothing after clear on empty map');

    shm_ii_put $map, 100, 200;
    ($k, $v) = shm_ii_each $map;
    ok(defined $k, 'each works after clear + re-populate');
    is($k, 100, 'each returns correct key after clear');
    is($v, 200, 'each returns correct value after clear');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, $_, $_ * 10 for 1..20;

    my $cur = shm_ii_cursor $map;
    shm_ii_cursor_next $cur;

    shm_ii_clear $map;
    is(shm_ii_size $map, 0, 'size 0 after clear with live cursor');

    undef $cur;  # must not underflow the iterating count

    shm_ii_put $map, $_, $_ for 1..100;
    is(shm_ii_size $map, 100, 'map functional after clear-with-cursor + destroy');
    ok(shm_ii_capacity($map) > 16, 'table grew after cursor destroy');

    unlink $path;
}

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

    for my $i (1..$inserted) {
        is($map->get($i), $i * 10, "entry $i still readable after full");
    }

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    my $default = "hello";
    my $got = shm_ss_get_or_set $map, "key1", $default;
    is($got, "hello", 'get_or_set returns default on insert');

    $got .= " world";
    is($got, "hello world", 'local mutation works');

    my $stored = shm_ss_get $map, "key1";
    is($stored, "hello", 'shared value unchanged after mutating returned SV');

    my $got2 = shm_ss_get_or_set $map, "key1", "other";
    is($got2, "hello", 'get_or_set returns existing value on second call');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put_ttl $map, 1, 100, 0;
    shm_ii_put $map, 2, 200;

    my $rem1 = shm_ii_ttl_remaining $map, 1;
    is($rem1, 0, 'ttl_remaining is 0 for permanent entry');

    my $rem2 = shm_ii_ttl_remaining $map, 2;
    ok(defined $rem2 && $rem2 > 0, 'ttl_remaining > 0 for TTL entry');

    Time::HiRes::sleep(2.2);

    my $v1 = shm_ii_get $map, 1;
    is($v1, 100, 'permanent entry (ttl=0) survives past default TTL');

    my $v2 = shm_ii_get $map, 2;
    ok(!defined $v2, 'default TTL entry expired');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 42;

    my $pid = fork();
    if ($pid == 0) {
        my $child_map = Data::HashMap::Shared::II->new($path, 1000);
        shm_ii_put $child_map, 2, 99;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    # Leave the lock as the reaped child would have: wlock at offset 128 holds
    # 0x80000000 | pid, seq at offset 64 is odd while a writer is active.
    open my $fh, '+<:raw', $path or die "Cannot open $path: $!";
    seek($fh, 128, 0);
    print $fh pack('V', 0x80000000 | $pid);
    seek($fh, 64, 0);
    print $fh pack('V', 1);
    close $fh;

    undef $map;
    $map = Data::HashMap::Shared::II->new($path, 1000);

    my $val = shm_ii_get $map, 1;   # recovers after the 2s lock timeout
    is($val, 42, 'recovered from stale lock without deadlock');
    ok(shm_ii_stat_recoveries($map) > 0, 'stat_recoveries incremented after recovery');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    shm_ii_put $map, 1, 1;
    undef $map;

    eval { Data::HashMap::Shared::SS->new($path, 100) };
    like($@, qr/variant mismatch/, 'variant mismatch gives diagnostic error');
    like($@, qr/the file is II, not SS/, 'error names both variants');

    unlink $path;
}

{
    eval { Data::HashMap::Shared::II->new('/nonexistent/path/test.shm', 100) };
    like($@, qr/No such file|Permission denied/, 'bad path gives errno in error');
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    shm_ii_put $map, 1, 42;
    ok(-f $path, 'backing file exists');
    ok($map->unlink, 'instance unlink returns true');
    ok(!-f $path, 'backing file removed after unlink');
    my $v = shm_ii_get $map, 1;
    is($v, 42, 'map still readable after unlink');
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    undef $map;
    ok(-f $path, 'backing file exists before class unlink');
    ok(Data::HashMap::Shared::II->unlink($path), 'class unlink returns true');
    ok(!-f $path, 'backing file removed after class unlink');
}

{
    ok(!Data::HashMap::Shared::II->unlink('/tmp/nonexistent_shm_test_' . $$ . '.shm'),
       'unlink returns false for non-existent file');
}

{
    my $path = tmpfile();
    # max_size 100, ttl 0, lru_skip 90 (percent of promotions skipped)
    my $map = Data::HashMap::Shared::II->new($path, 10000, 100, 0, 90);

    shm_ii_put $map, $_, $_ for 1..100;

    shm_ii_get $map, 50 for 1..20;
    my $v = shm_ii_get $map, 50;
    is($v, 50, 'lru_skip: frequently accessed key still readable');

    shm_ii_put $map, 100 + $_, 100 + $_ for 1..50;
    is(shm_ii_size $map, 100, 'lru_skip: map stays at max_size');
    ok(shm_ii_stat_evictions($map) >= 50, 'lru_skip: evictions occurred');

    my $count = 0;
    while (my ($k, $v) = shm_ii_each $map) { $count++ }
    is($count, 100, 'lru_skip: iteration returns exactly max_size entries');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 5, 0, 0);

    shm_ii_put $map, $_, $_ for 1..5;
    shm_ii_get $map, 1;
    shm_ii_put $map, 6, 6;
    my $v2 = shm_ii_get $map, 2;
    ok(!defined $v2, 'lru_skip=0: key 2 evicted (strict LRU)');
    my $v1 = shm_ii_get $map, 1;
    is($v1, 1, 'lru_skip=0: key 1 survived (was promoted)');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..3;

    my ($k, $v) = shm_ii_pop $map;
    ok(defined $k, 'pop returns entry from non-LRU map');
    is($v, $k * 10, 'pop value matches key');
    is(shm_ii_size $map, 2, 'pop decrements size');

    shm_ii_pop $map;
    shm_ii_pop $map;
    my ($ek, $ev) = shm_ii_pop $map;
    ok(!defined $ek, 'pop on empty map returns undef');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 100);
    shm_ii_put $map, $_, $_ for 1..5;
    shm_ii_get $map, 3;  # promote key 3 to MRU

    my ($k1) = shm_ii_pop $map;
    is($k1, 1, 'pop LRU: evicts tail (key 1)');
    my ($k2) = shm_ii_pop $map;
    is($k2, 2, 'pop LRU: evicts next tail (key 2)');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..5;

    my @got = shm_ii_drain $map, 2;
    is(scalar @got, 4, 'drain 2 returns 4 elements (2 pairs)');
    is(shm_ii_size $map, 3, 'drain 2 leaves 3 entries');

    @got = shm_ii_drain $map, 100;
    is(scalar @got, 6, 'drain rest returns 6 elements (3 pairs)');
    is(shm_ii_size $map, 0, 'drain empties map');

    @got = shm_ii_drain $map, 5;
    is(scalar @got, 0, 'drain empty returns nothing');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 100);
    shm_ii_put $map, $_, $_ for 1..4;
    shm_ii_get $map, 2;  # mark key 2 as accessed

    my @got = shm_ii_drain $map, 4;
    my %drained = @got;
    is(scalar keys %drained, 4, 'drain LRU returns all 4 entries');
    is($drained{$_}, $_, "drain LRU: key $_ has correct value") for 1..4;
    is(shm_ii_size $map, 0, 'drain LRU empties map');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "a", "alpha";
    shm_ss_put $map, "b", "beta";

    my ($k, $v) = shm_ss_pop $map;
    ok(defined $k && defined $v, 'SS pop returns key+value');
    is(shm_ss_size $map, 1, 'SS pop decrements size');

    my @d = shm_ss_drain $map, 10;
    is(scalar @d, 2, 'SS drain returns remaining pair');
    is(shm_ss_size $map, 0, 'SS drain empties map');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 100);
    shm_ii_put $map, $_, $_ for 1..5;

    my ($pk) = shm_ii_pop $map;
    my ($sk) = shm_ii_shift $map;
    ok(defined $pk, 'pop returns entry from LRU map');
    ok(defined $sk, 'shift returns entry from LRU map');
    ok($pk != $sk, 'pop and shift return different entries');
    is(shm_ii_size $map, 3, 'pop+shift removed 2 entries');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..3;

    my ($sk, $sv) = shm_ii_shift $map;
    ok(defined $sk, 'shift returns entry from non-LRU map');
    is($sv, $sk * 10, 'shift value matches');
    is(shm_ii_size $map, 2, 'shift decrements size');

    shm_ii_shift $map;
    shm_ii_shift $map;
    my ($ek) = shm_ii_shift $map;
    ok(!defined $ek, 'shift on empty map returns undef');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 100);
    shm_ii_put $map, $_, $_ for 1..4;

    my %got;
    my ($p1) = shm_ii_pop $map;    $got{$p1}++ if defined $p1;
    my ($s1) = shm_ii_shift $map;  $got{$s1}++ if defined $s1;
    my ($p2) = shm_ii_pop $map;    $got{$p2}++ if defined $p2;
    my ($s2) = shm_ii_shift $map;  $got{$s2}++ if defined $s2;
    is(scalar keys %got, 4, 'pop+shift returned all 4 unique entries');
    is(shm_ii_size $map, 0, 'map empty after pop+shift all');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    is(shm_ii_arena_used $map, 0, 'II arena_used is 0 (no arena)');
    is(shm_ii_arena_cap $map, 0, 'II arena_cap is 0 (no arena)');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $cap = shm_ss_arena_cap $map;
    ok($cap > 0, 'SS arena_cap > 0');
    my $before = shm_ss_arena_used $map;
    shm_ss_put $map, "a_longer_key", "a_longer_value";
    my $after = shm_ss_arena_used $map;
    ok($after > $before, 'SS arena_used increases after put');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    my $r1 = shm_ii_add $map, 1, 100;
    ok($r1, 'add succeeds on empty map');
    my $r2 = shm_ii_add $map, 1, 200;
    ok(!$r2, 'add fails if key exists');
    my $v = shm_ii_get $map, 1;
    is($v, 100, 'add did not overwrite existing value');
    my $sz = shm_ii_size $map;
    is($sz, 1, 'add does not change size on duplicate');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);
    shm_ii_put $map, 1, 100;
    Time::HiRes::sleep(2.2);
    my $r = shm_ii_add $map, 1, 200;
    ok($r, 'add succeeds after TTL expiry');
    my $v = shm_ii_get $map, 1;
    is($v, 200, 'add inserted new value after expiry');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    my $r1 = shm_ii_update $map, 1, 100;
    ok(!$r1, 'update fails on empty map');
    shm_ii_put $map, 1, 100;
    my $r2 = shm_ii_update $map, 1, 999;
    ok($r2, 'update succeeds if key exists');
    my $v = shm_ii_get $map, 1;
    is($v, 999, 'update changed value');
    my $sz = shm_ii_size $map;
    is($sz, 1, 'update does not change size');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    my $old1 = shm_ii_swap $map, 1, 100;
    ok(!defined $old1, 'swap on new key returns undef');
    my $v1 = shm_ii_get $map, 1;
    is($v1, 100, 'swap inserted value');

    my $old2 = shm_ii_swap $map, 1, 200;
    is($old2, 100, 'swap returns old value');
    my $v2 = shm_ii_get $map, 1;
    is($v2, 200, 'swap updated to new value');
    my $sz = shm_ii_size $map;
    is($sz, 1, 'swap did not change size');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $old1 = shm_ss_swap $map, "key", "val1";
    ok(!defined $old1, 'SS swap new returns undef');
    my $old2 = shm_ss_swap $map, "key", "val2";
    is($old2, "val1", 'SS swap returns old string');
    my $v = shm_ss_get $map, "key";
    is($v, "val2", 'SS swap updated value');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_add $map, 1, 10;
    shm_ii_add $map, 2, 20;
    shm_ii_add $map, 3, 30;
    my $u = shm_ii_update $map, 99, 0;
    ok(!$u, 'update nonexistent');
    shm_ii_update $map, 2, 222;
    my $old = shm_ii_swap $map, 3, 333;
    is($old, 30, 'swap got old value');
    my $g1 = shm_ii_get $map, 1;
    my $g2 = shm_ii_get $map, 2;
    my $g3 = shm_ii_get $map, 3;
    is($g1, 10, 'key 1 unchanged');
    is($g2, 222, 'key 2 updated');
    is($g3, 333, 'key 3 swapped');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 100;

    my $r1 = shm_ii_cas $map, 1, 100, 200;
    ok($r1, 'cas succeeds when expected matches');
    my $v = shm_ii_get $map, 1;
    is($v, 200, 'cas updated value');

    my $r2 = shm_ii_cas $map, 1, 100, 300;
    ok(!$r2, 'cas fails when expected does not match');
    $v = shm_ii_get $map, 1;
    is($v, 200, 'cas did not change value on mismatch');

    my $r3 = shm_ii_cas $map, 99, 0, 1;
    ok(!$r3, 'cas fails on nonexistent key');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);
    shm_ii_put $map, 1, 100;

    my $rem = shm_ii_ttl_remaining $map, 1;
    ok($rem > 0, 'key has TTL before persist');
    my $r = shm_ii_persist $map, 1;
    ok($r, 'persist succeeds');
    $rem = shm_ii_ttl_remaining $map, 1;
    is($rem, 0, 'key is permanent after persist');

    my $r2 = shm_ii_persist $map, 99;
    ok(!$r2, 'persist fails on nonexistent key');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);
    shm_ii_put $map, 1, 100;

    my $r = shm_ii_set_ttl $map, 1, 30;
    ok($r, 'set_ttl succeeds');
    my $rem = shm_ii_ttl_remaining $map, 1;
    ok($rem > 0 && $rem <= 30, 'TTL changed to 30');
    my $v = shm_ii_get $map, 1;
    is($v, 100, 'value unchanged after set_ttl');

    shm_ii_set_ttl $map, 1, 0;
    $rem = shm_ii_ttl_remaining $map, 1;
    is($rem, 0, 'set_ttl 0 makes key permanent');

    my $r2 = shm_ii_set_ttl $map, 99, 10;
    ok(!$r2, 'set_ttl fails on nonexistent key');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 50, 60);
    shm_ii_put $map, $_, $_ for 1..10;

    my $s = $map->stats;
    is(ref $s, 'HASH', 'stats returns hashref');
    is($s->{size}, 10, 'stats size correct');
    ok($s->{capacity} >= 16, 'stats capacity present');
    is($s->{max_size}, 50, 'stats max_size correct');
    is($s->{ttl}, 60, 'stats ttl correct');
    ok(exists $s->{tombstones}, 'stats has tombstones');
    ok(exists $s->{mmap_size}, 'stats has mmap_size');
    ok(exists $s->{evictions}, 'stats has evictions');
    ok(exists $s->{expired}, 'stats has expired');
    ok(exists $s->{recoveries}, 'stats has recoveries');
    ok(exists $s->{arena_used}, 'stats has arena_used');
    ok(exists $s->{arena_cap}, 'stats has arena_cap');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "k", "v";
    my $s = $map->stats;
    ok($s->{arena_cap} > 0, 'SS stats arena_cap > 0');
    ok($s->{arena_used} > 0, 'SS stats arena_used > 0');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000);
    my $n = $map->set_multi(1, 10, 2, 20, 3, 30);
    is($n, 3, 'set_multi returns count of successful puts');
    my $sz = shm_ii_size $map;
    is($sz, 3, 'set_multi inserted 3 entries');
    my $v = shm_ii_get $map, 2;
    is($v, 20, 'set_multi values correct');

    $n = $map->set_multi(2, 222, 4, 40);
    is($n, 2, 'set_multi overwrite+insert returns 2');
    $v = shm_ii_get $map, 2;
    is($v, 222, 'set_multi overwrote existing');
    $v = shm_ii_get $map, 4;
    is($v, 40, 'set_multi inserted new');
    $sz = shm_ii_size $map;
    is($sz, 4, 'set_multi size correct after overwrite+insert');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 10000);
    my $n = $map->set_multi("a", "alpha", "b", "beta");
    is($n, 2, 'SS set_multi inserted 2');
    my $v = shm_ss_get $map, "a";
    is($v, "alpha", 'SS set_multi value correct');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000);
    eval { $map->set_multi(1, 10, 2) };
    like($@, qr/even number/, 'set_multi croaks on odd args');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 10);
    shm_ii_put $map, $_, $_ for 1..10;
    shm_ii_get $map, 1;
    shm_ii_put $map, 99, 99;
    my $sz = shm_ii_size $map;
    is($sz, 10, 'clock: map stays at max_size after overflow');
    my $v = shm_ii_get $map, 1;
    ok(defined $v, 'clock: accessed key survives single eviction (second chance)');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 5);
    shm_ii_put $map, $_, $_ for 1..5;
    my $old = shm_ii_swap $map, 99, 999;
    ok(!defined $old, 'swap on LRU: new key returns undef');
    my $v = shm_ii_get $map, 99;
    is($v, 999, 'swap on LRU: new key inserted');
    my $sz = shm_ii_size $map;
    is($sz, 5, 'swap on LRU: size stays at max_size');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 5);
    shm_ii_put $map, $_, $_ for 1..5;
    my $r = shm_ii_add $map, 99, 999;
    ok($r, 'add on LRU at capacity: succeeds (evicts)');
    my $sz = shm_ii_size $map;
    is($sz, 5, 'add on LRU at capacity: size stays at max_size');
    my $v = shm_ii_get $map, 99;
    is($v, 999, 'add on LRU at capacity: new key present');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    $map->set_multi(1, 10, 2, 20, 3, 30);
    my $rem = shm_ii_ttl_remaining $map, 1;
    ok(defined $rem && $rem > 0, 'set_multi with TTL: entries have TTL');
    Time::HiRes::sleep(2.2);
    my $v = shm_ii_get $map, 1;
    ok(!defined $v, 'set_multi with TTL: entries expire');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    shm_ii_put $map, 1, 100;
    shm_ii_persist $map, 1;
    Time::HiRes::sleep(2.2);
    my $v = shm_ii_get $map, 1;
    is($v, 100, 'persist then get: entry survives past original TTL');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 60);
    shm_ii_put_ttl $map, 1, 100, 0;
    my $rem = shm_ii_ttl_remaining $map, 1;
    is($rem, 0, 'permanent entry has ttl_remaining=0');
    shm_ii_set_ttl $map, 1, 2;
    $rem = shm_ii_ttl_remaining $map, 1;
    ok($rem > 0 && $rem <= 2, 'set_ttl re-adds TTL to permanent entry');
    Time::HiRes::sleep(2.2);
    my $v = shm_ii_get $map, 1;
    ok(!defined $v, 'entry expires after set_ttl re-added TTL');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    shm_ii_put $map, $_, $_ * 10 for 1..5;
    shm_ii_put_ttl $map, 99, 990, 0;
    Time::HiRes::sleep(2.2);
    my ($k, $v) = shm_ii_pop $map;
    is($k, 99, 'pop on TTL map skips expired, returns live entry');
    is($v, 990, 'pop on TTL map returns correct value');
    my ($ek) = shm_ii_pop $map;
    ok(!defined $ek, 'pop on TTL map with all expired returns undef');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    shm_ii_put $map, 1, 100;
    Time::HiRes::sleep(2.2);
    my $r = shm_ii_cas $map, 1, 100, 200;
    ok(!$r, 'cas on expired key returns false');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    shm_ii_put $map, $_, $_ for 1..3;
    shm_ii_put_ttl $map, 99, 99, 0;
    Time::HiRes::sleep(2.2);
    my @got = shm_ii_drain $map, 10;
    is(scalar @got, 2, 'drain on TTL map returns only live entries (1 pair)');
    is($got[0], 99, 'drain on TTL map: live key is 99');
    is($got[1], 99, 'drain on TTL map: live value is 99');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "key1", "";
    shm_ss_put $map, "key2", "hello";
    my $v1 = shm_ss_get $map, "key1";
    is($v1, "", 'empty string value: get returns empty string');
    ok(defined $v1, 'empty string value: defined (not undef)');
    my $v2 = shm_ss_get $map, "key2";
    is($v2, "hello", 'non-empty value: unchanged');
    shm_ss_put $map, "key2", "";
    $v2 = shm_ss_get $map, "key2";
    is($v2, "", 'overwrite with empty string works');
    my $sz = shm_ss_size $map;
    is($sz, 2, 'empty strings: correct size');
    unlink $path;
}

# exercises the SSE2 shm_find_next_live scan over a sparse table
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000);
    shm_ii_put $map, $_, $_ for 1..100;
    shm_ii_remove $map, $_ for 1..90;
    my $sz = shm_ii_size $map;
    is($sz, 10, 'sparse: 10 entries remain after bulk delete');
    my $count = 0;
    while (my ($k, $v) = shm_ii_each $map) {
        ok($k >= 91 && $k <= 100, "sparse: each returns key $k in range 91-100");
        is($v, $k, "sparse: value matches key");
        $count++;
    }
    is($count, 10, 'sparse: each returns exactly 10 entries');
    my $cur = shm_ii_cursor $map;
    $count = 0;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { $count++ }
    is($count, 10, 'sparse: cursor returns exactly 10 entries');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100000);
    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 100000);
        $child->set_multi(map { ($_, $_ * 10) } 1001..2000);
        POSIX::_exit(0);
    }
    $map->set_multi(map { ($_, $_ * 10) } 1..1000);
    waitpid($pid, 0);
    my $sz = shm_ii_size $map;
    is($sz, 2000, 'concurrent set_multi: all 2000 entries present');
    my $v = shm_ii_get $map, 1500;
    is($v, 15000, 'concurrent set_multi: value correct');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 5);
    shm_ii_put $map, $_, $_ for 1..5;

    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 10000, 5);
        shm_ii_get $child, 1;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    shm_ii_put $map, 99, 99;
    my $v = shm_ii_get $map, 1;
    ok(defined $v, 'cross-process clock: child accessed bit gives second chance');
    my $sz = shm_ii_size $map;
    is($sz, 5, 'cross-process clock: size stays at max');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
    shm_ii_put $map, 1, 100;

    my $pid = fork();
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, 10000, 0, 2);
        shm_ii_persist $child, 1;
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    Time::HiRes::sleep(2.2);
    my $v = shm_ii_get $map, 1;
    is($v, 100, 'cross-process persist: key survives past TTL');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    my $r = shm_ii_reserve $map, 10000;
    ok(!$r, 'reserve beyond max_table_cap returns false');
    shm_ii_put $map, 1, 1;
    my $rv = shm_ii_get $map, 1;
    is($rv, 1, 'map functional after failed reserve');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 50);
    my $filled = 0;
    for my $i (1..50) {
        my $r = shm_ss_put $map, "k$i", "x" x 100;
        last unless $r;
        $filled++;
    }
    ok($filled > 0 && $filled < 50, "arena fill: inserted $filled before full");
    shm_ss_remove $map, "k1";
    shm_ss_remove $map, "k2";
    my $r = shm_ss_put $map, "new", "small";
    ok($r, 'arena: smaller put succeeds after remove (free-list reclaim)');
    my $v = shm_ss_get $map, "new";
    is($v, "small", 'arena: reclaimed value correct');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    shm_ii_put $map, 1, 1;
    undef $map;
    # the version field is at header offset 4
    open my $fh, '+<:raw', $path or die;
    seek($fh, 4, 0);
    print $fh pack('V', 999);
    close $fh;
    eval { Data::HashMap::Shared::II->new($path, 100) };
    like($@, qr/version mismatch/, 'wrong SHM_VERSION gives version mismatch error');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 0);
    my $cap = shm_ii_capacity $map;
    ok($cap >= 16, 'max_entries=0: creates with initial capacity');
    shm_ii_put $map, 1, 42;
    my $v = shm_ii_get $map, 1;
    is($v, 42, 'max_entries=0: put/get works');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $key = "\x{263A}";
    my $val = "\x{1F600}";
    utf8::encode($key) unless utf8::is_utf8($key);
    utf8::decode($key);
    utf8::encode($val) unless utf8::is_utf8($val);
    utf8::decode($val);
    ok(utf8::is_utf8($key), 'UTF-8 key has flag set');
    ok(utf8::is_utf8($val), 'UTF-8 val has flag set');
    shm_ss_put $map, $key, $val;
    my $got = shm_ss_get $map, $key;
    is($got, $val, 'UTF-8 value round-trips correctly');
    ok(utf8::is_utf8($got), 'UTF-8 flag preserved on get');
    my $e = shm_ss_exists $map, $key;
    ok($e, 'UTF-8 key: exists returns true');
    my $taken = shm_ss_take $map, $key;
    is($taken, $val, 'UTF-8 value: take returns correct value');
    ok(utf8::is_utf8($taken), 'UTF-8 flag preserved on take');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..100;
    my $sz = shm_ii_size $map;
    is($sz, 100, 'sharded: size correct');
    my $v = shm_ii_get $map, 42;
    is($v, 420, 'sharded: get correct');
    shm_ii_remove $map, 50;
    my $e = shm_ii_exists $map, 50;
    ok(!$e, 'sharded: remove works');
    $sz = shm_ii_size $map;
    is($sz, 99, 'sharded: size after remove');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, 1, 0;
    shm_ii_incr $map, 1;
    shm_ii_incr_by $map, 1, 10;
    my $v = shm_ii_get $map, 1;
    is($v, 11, 'sharded: incr works');
    my $r = shm_ii_cas $map, 1, 11, 42;
    ok($r, 'sharded: cas succeeds');
    $v = shm_ii_get $map, 1;
    is($v, 42, 'sharded: cas updated');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new_sharded($path, 4, 1000);
    shm_ss_put $map, "key$_", "val$_" for 1..50;
    my $sz = shm_ss_size $map;
    is($sz, 50, 'sharded SS: size correct');
    my $v = shm_ss_get $map, "key25";
    is($v, "val25", 'sharded SS: get correct');
    shm_ss_remove $map, "key1";
    $v = shm_ss_get $map, "key1";
    ok(!defined $v, 'sharded SS: remove works');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    my $r1 = shm_ii_add $map, 1, 100;
    ok($r1, 'sharded: add succeeds');
    my $r2 = shm_ii_add $map, 1, 200;
    ok(!$r2, 'sharded: add fails if exists');
    my $r3 = shm_ii_update $map, 1, 999;
    ok($r3, 'sharded: update succeeds');
    my $old = shm_ii_swap $map, 1, 42;
    is($old, 999, 'sharded: swap returns old value');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..50;

    my $cur = shm_ii_cursor $map;
    my %seen;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { $seen{$k} = $v }
    is(scalar keys %seen, 50, 'sharded cursor visits all entries across shards');
    ok((grep { $seen{$_} == $_ * 10 } 1..50) == 50, 'sharded cursor values correct');

    shm_ii_cursor_reset $cur;
    my $count = 0;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { $count++ }
    is($count, 50, 'sharded cursor reset re-scans all shards');

    my $c2 = shm_ii_cursor $map;
    my $found = shm_ii_cursor_seek $c2, 25;
    ok($found, 'sharded cursor seek finds key');
    my ($k2, $v2) = shm_ii_cursor_next $c2;
    is($k2, 25, 'sharded cursor seek positions correctly');
    is($v2, 250, 'sharded cursor seek value correct');

    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new_sharded($path, 4, 1000);
    shm_ss_put $map, "k$_", "v$_" for 1..20;
    my $cur = shm_ss_cursor $map;
    my $count = 0;
    while (my ($k, $v) = shm_ss_cursor_next $cur) { $count++ }
    is($count, 20, 'sharded SS cursor visits all entries');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..50;
    my @k = sort { $a <=> $b } shm_ii_keys $map;
    is(scalar @k, 50, 'sharded: keys count');
    is_deeply(\@k, [1..50], 'sharded: keys correct');
    my @v = sort { $a <=> $b } shm_ii_values $map;
    is_deeply(\@v, [map { $_ * 10 } 1..50], 'sharded: values correct');
    my @items = shm_ii_items $map;
    is(scalar @items, 100, 'sharded: items count (flat k,v pairs)');
    my %from_items = @items;
    is($from_items{25}, 250, 'sharded: items content');
    my $href = shm_ii_to_hash $map;
    is(scalar keys %$href, 50, 'sharded: to_hash count');
    is($href->{10}, 100, 'sharded: to_hash content');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 2 for 1..30;
    my %seen;
    while (my ($k, $v) = shm_ii_each $map) { $seen{$k} = $v; }
    is(scalar keys %seen, 30, 'sharded: each visits all');
    is($seen{15}, 30, 'sharded: each values correct');
    my $count = 0;
    while (my ($k, $v) = shm_ii_each $map) { $count++; }
    is($count, 30, 'sharded: each auto-reset works');
    shm_ii_iter_reset $map;
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    my $n = $map->set_multi(1, 10, 2, 20, 3, 30, 4, 40, 5, 50);
    is($n, 5, 'sharded: set_multi returns count');
    my $v3 = shm_ii_get $map, 3;
    is($v3, 30, 'sharded: set_multi values correct');
    my $sz = shm_ii_size $map;
    is($sz, 5, 'sharded: set_multi size');
    my $rm = $map->remove_multi(1, 3, 99);
    is($rm, 2, 'sharded: remove_multi returns count of existing keys removed');
    ok(!(shm_ii_exists $map, 1) && !(shm_ii_exists $map, 3), 'sharded: remove_multi removed the keys');
    is(shm_ii_size $map, 3, 'sharded: size after remove_multi');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 100 for 1..20;
    my $v = shm_ii_take $map, 10;
    is($v, 1000, 'sharded: take returns value');
    my $e = shm_ii_exists $map, 10;
    ok(!$e, 'sharded: take removes key');
    my $sz = shm_ii_size $map;
    is($sz, 19, 'sharded: size after take');
    my ($pk, $pv) = shm_ii_pop $map;
    ok(defined $pk, 'sharded: pop returns key');
    $sz = shm_ii_size $map;
    is($sz, 18, 'sharded: size after pop');
    my ($sk, $sv) = shm_ii_shift $map;
    ok(defined $sk, 'sharded: shift returns key');
    $sz = shm_ii_size $map;
    is($sz, 17, 'sharded: size after shift');
    my @drained = shm_ii_drain $map, 5;
    is(scalar @drained, 10, 'sharded: drain returns 5 k/v pairs');
    $sz = shm_ii_size $map;
    is($sz, 12, 'sharded: size after drain');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    my $v1 = shm_ii_get_or_set $map, 42, 100;
    is($v1, 100, 'sharded: get_or_set inserts');
    my $v2 = shm_ii_get_or_set $map, 42, 999;
    is($v2, 100, 'sharded: get_or_set returns existing');
    my $n = shm_ii_incr_by $map, 42, 5;
    is($n, 105, 'sharded: incr_by works');
    my $d = shm_ii_decr $map, 42;
    is($d, 104, 'sharded: decr works');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ for 1..50;
    my $sz = shm_ii_size $map;
    is($sz, 50, 'sharded: size before clear');
    shm_ii_clear $map;
    $sz = shm_ii_size $map;
    is($sz, 0, 'sharded: size after clear');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000, 0, 60);
    shm_ii_put $map, $_, $_ * 10 for 1..20;
    shm_ii_put_ttl $map, 100, 999, 5;
    my $rem = shm_ii_ttl_remaining $map, 100;
    ok($rem > 0 && $rem <= 5, 'sharded: ttl_remaining correct');
    my $touched = shm_ii_touch $map, 1;
    ok($touched, 'sharded: touch works');
    my $persisted = shm_ii_persist $map, 2;
    ok($persisted, 'sharded: persist works');
    my $rem2 = shm_ii_ttl_remaining $map, 2;
    is($rem2, 0, 'sharded: persist makes permanent');
    ok($map->set_ttl(3, 120), 'sharded: set_ttl works');
    my $rem3 = shm_ii_ttl_remaining $map, 3;
    ok($rem3 > 60 && $rem3 <= 120, 'sharded: set_ttl updated');
    my $ttl = shm_ii_ttl $map;
    is($ttl, 60, 'sharded: ttl returns default');
    my $ms = shm_ii_max_size $map;
    is($ms, 0, 'sharded: max_size 0 (no LRU)');
    my $flushed = shm_ii_flush_expired $map;
    is($flushed, 0, 'sharded: flush_expired 0 when nothing expired');
    my ($partial_n, $partial_done) = shm_ii_flush_expired_partial $map, 100;
    is($partial_n, 0, 'sharded: flush_expired_partial 0');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ for 1..40;
    my $s = $map->stats;
    is($s->{size}, 40, 'sharded: stats size');
    ok($s->{capacity} >= 40, 'sharded: stats capacity');
    ok($s->{max_entries} >= 1000, 'sharded: stats max_entries');
    ok($s->{mmap_size} > 0, 'sharded: stats mmap_size');
    is($s->{evictions}, 0, 'sharded: stats evictions');
    is($s->{expired}, 0, 'sharded: stats expired');
    is($s->{recoveries}, 0, 'sharded: stats recoveries');
    my $cap = shm_ii_capacity $map;
    ok($cap >= 40, 'sharded: capacity keyword');
    my $tb = shm_ii_tombstones $map;
    is($tb, 0, 'sharded: tombstones keyword');
    my $ms = shm_ii_mmap_size $map;
    ok($ms > 0, 'sharded: mmap_size keyword');
    my $me = shm_ii_max_entries $map;
    ok($me >= 1000, 'sharded: max_entries keyword');
    my $au = shm_ii_arena_used $map;
    is($au, 0, 'sharded: arena_used 0 for II');
    my $ac = shm_ii_arena_cap $map;
    is($ac, 0, 'sharded: arena_cap 0 for II');
    my $ev = shm_ii_stat_evictions $map;
    is($ev, 0, 'sharded: stat_evictions keyword');
    my $ex = shm_ii_stat_expired $map;
    is($ex, 0, 'sharded: stat_expired keyword');
    my $rc = shm_ii_stat_recoveries $map;
    is($rc, 0, 'sharded: stat_recoveries keyword');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    my $ok = shm_ii_reserve $map, 500;
    ok($ok, 'sharded: reserve succeeds');
    my $cap = shm_ii_capacity $map;
    ok($cap >= 500, 'sharded: capacity after reserve');
    is($map->path, $path, 'sharded: path returns prefix');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new_sharded($path, 4, 1000);
    shm_ss_put $map, "k$_", "v$_" for 1..30;
    my @k = sort(shm_ss_keys $map);
    is(scalar @k, 30, 'sharded SS: keys count');
    is($k[0], 'k1', 'sharded SS: keys sorted first');
    my @v = sort(shm_ss_values $map);
    is(scalar @v, 30, 'sharded SS: values count');
    my $href = shm_ss_to_hash $map;
    is($href->{k15}, 'v15', 'sharded SS: to_hash content');
    my $n = $map->set_multi('a', 'A', 'b', 'B', 'c', 'C');
    is($n, 3, 'sharded SS: set_multi count');
    my $bval = shm_ss_get $map, 'b';
    is($bval, 'B', 'sharded SS: set_multi value');
    my $tv = shm_ss_take $map, 'k10';
    is($tv, 'v10', 'sharded SS: take returns value');
    my @drained = shm_ss_drain $map, 3;
    is(scalar @drained, 6, 'sharded SS: drain returns 3 k/v pairs');
    my $sz = shm_ss_size $map;
    is($sz, 29, 'sharded SS: size after take+drain');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 100);
    shm_ii_put $map, 1, 1;
    $map->unlink;
    ok(!-e "$path.0", 'sharded: unlink removes shard files');
    ok(!-e "$path.3", 'sharded: unlink removes all shard files');
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 30);

    shm_ii_put $map, 1, 100;
    my $rem_before = shm_ii_ttl_remaining $map, 1;
    ok($rem_before > 0, 'cas ttl: key has TTL');
    my $ok = shm_ii_cas $map, 1, 100, 200;
    ok($ok, 'cas ttl: cas succeeded');
    my $rem_after = shm_ii_ttl_remaining $map, 1;
    ok($rem_after > 0, 'cas ttl: TTL refreshed after cas');
    is((shm_ii_get $map, 1), 200, 'cas ttl: value updated');

    shm_ii_put $map, 2, 10;
    my $u = shm_ii_update $map, 2, 20;
    ok($u, 'update ttl: update succeeded');
    my $rem_u = shm_ii_ttl_remaining $map, 2;
    ok($rem_u > 0, 'update ttl: TTL refreshed');

    shm_ii_put $map, 3, 30;
    my $old = $map->swap(3, 40);
    is($old, 30, 'swap ttl: old value returned');
    my $rem_s = shm_ii_ttl_remaining $map, 3;
    ok($rem_s > 0, 'swap ttl: TTL refreshed');

    shm_ii_put $map, 4, 40;
    my $a = shm_ii_add $map, 4, 50;
    ok(!$a, 'add ttl: add fails on existing key');
    is((shm_ii_get $map, 4), 40, 'add ttl: value unchanged');

    my $a2 = shm_ii_add $map, 5, 50;
    ok($a2, 'add ttl: add succeeds on new key');
    my $rem_a = shm_ii_ttl_remaining $map, 5;
    ok($rem_a > 0, 'add ttl: new key has TTL');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);
    shm_ii_put_ttl $map, 1, 100, 0;
    my $rem0 = shm_ii_ttl_remaining $map, 1;
    is($rem0, 0, 'put_ttl permanent: entry is permanent');
    shm_ii_put_ttl $map, 1, 200, 30;
    my $rem1 = shm_ii_ttl_remaining $map, 1;
    ok($rem1 > 0 && $rem1 <= 30, 'put_ttl permanent: explicit TTL applied');
    is((shm_ii_get $map, 1), 200, 'put_ttl permanent: value updated');

    shm_ii_put_ttl $map, 2, 10, 0;
    shm_ii_put $map, 2, 20;
    my $rem2 = shm_ii_ttl_remaining $map, 2;
    is($rem2, 0, 'put on permanent: stays permanent');
    is((shm_ii_get $map, 2), 20, 'put on permanent: value updated');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..100;
    my @vals = $map->get_multi(1, 50, 100, 999);
    is(scalar @vals, 4, 'get_multi: returns N values');
    is($vals[0], 10, 'get_multi: first key correct');
    is($vals[1], 500, 'get_multi: middle key correct');
    is($vals[2], 1000, 'get_multi: last key correct');
    ok(!defined $vals[3], 'get_multi: missing key returns undef');
    my @empty = $map->get_multi();
    is(scalar @empty, 0, 'get_multi: empty args returns empty list');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "k$_", "v$_" for 1..50;
    my @vals = $map->get_multi('k1', 'k25', 'k50', 'missing');
    is(scalar @vals, 4, 'get_multi SS: returns N values');
    is($vals[0], 'v1', 'get_multi SS: first value');
    is($vals[1], 'v25', 'get_multi SS: middle value');
    is($vals[2], 'v50', 'get_multi SS: last value');
    ok(!defined $vals[3], 'get_multi SS: missing returns undef');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000);
    shm_ii_put $map, $_, $_ * 5 for 1..50;
    my @vals = $map->get_multi(1, 25, 50, 999);
    is(scalar @vals, 4, 'get_multi sharded: returns N values');
    is($vals[0], 5, 'get_multi sharded: first correct');
    is($vals[1], 125, 'get_multi sharded: middle correct');
    ok(!defined $vals[3], 'get_multi sharded: missing returns undef');
    unlink "$path.$_" for 0..3;
}

# 7 bytes is the inline maximum; 8 bytes goes to the arena
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $k7 = "1234567";
    my $k8 = "12345678";
    my $v7 = "abcdefg";
    my $v8 = "abcdefgh";
    shm_ss_put $map, $k7, $v7;
    shm_ss_put $map, $k8, $v8;
    is((shm_ss_get $map, $k7), $v7, 'inline boundary: 7-byte key+val roundtrip');
    is((shm_ss_get $map, $k8), $v8, 'inline boundary: 8-byte key+val roundtrip');
    shm_ss_put $map, "short", $v8;
    shm_ss_put $map, $k8, "tiny";
    is((shm_ss_get $map, "short"), $v8, 'inline boundary: inline key, arena val');
    is((shm_ss_get $map, $k8), "tiny", 'inline boundary: arena key, inline val');
    shm_ss_put $map, $k7, $v8;
    is((shm_ss_get $map, $k7), $v8, 'inline boundary: inline→arena val update');
    shm_ss_put $map, $k7, "x";
    is((shm_ss_get $map, $k7), "x", 'inline boundary: arena→inline val update');
    unlink $path;
}

# short keys: some must land in the first 16 probe positions (SIMD fast path)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 10000);
    shm_ss_put $map, "k$_", "v$_" for 1..500;
    my $ok = 1;
    for (1..500) {
        my $v = shm_ss_get $map, "k$_";
        $ok = 0 unless defined $v && $v eq "v$_";
    }
    ok($ok, 'SIMD probe: all 500 short string keys found');
    my $path2 = tmpfile();
    my $si = Data::HashMap::Shared::SI->new($path2, 10000);
    shm_si_put $si, "k$_", $_ for 1..500;
    $ok = 1;
    for (1..500) {
        my $v = shm_si_get $si, "k$_";
        $ok = 0 unless defined $v && $v == $_;
    }
    ok($ok, 'SIMD probe: all 500 SI short keys found');
    unlink $path;
    unlink $path2;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);
    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;
    shm_ii_put_ttl $map, 3, 30, 2;
    Time::HiRes::sleep(2.2);
    my @vals = $map->get_multi(1, 2, 3);
    is($vals[0], 10, 'get_multi TTL: non-expired key 1');
    is($vals[1], 20, 'get_multi TTL: non-expired key 2');
    ok(!defined $vals[2], 'get_multi TTL: expired key returns undef');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new_sharded($path, 4, 1000);
    shm_ss_put $map, "k$_", "v$_" for 1..50;
    my @vals = $map->get_multi('k1', 'k25', 'k50', 'missing');
    is(scalar @vals, 4, 'get_multi SS sharded: returns 4');
    is($vals[0], 'v1', 'get_multi SS sharded: first');
    is($vals[1], 'v25', 'get_multi SS sharded: middle');
    is($vals[2], 'v50', 'get_multi SS sharded: last');
    ok(!defined $vals[3], 'get_multi SS sharded: missing undef');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 100000);
    shm_ss_put $map, "k$_", "v$_" for 1..2000;
    my $sz = shm_ss_size $map;
    is($sz, 2000, 'resize inline: size correct after bulk insert');
    my $cap = shm_ss_capacity $map;
    ok($cap >= 2000, 'resize inline: capacity grew');
    my $ok = 1;
    for (1..2000) {
        my $v = shm_ss_get $map, "k$_";
        $ok = 0 unless defined $v && $v eq "v$_";
    }
    ok($ok, 'resize inline: all 2000 inline entries survive resize');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "k$_", "v$_" for 1..20;
    my $tv = shm_ss_take $map, 'k5';
    is($tv, 'v5', 'inline take: returns inline value');
    my ($pk, $pv) = shm_ss_pop $map;
    ok(defined $pk && defined $pv, 'inline pop: returns key+value');
    my ($sk, $sv) = shm_ss_shift $map;
    ok(defined $sk && defined $sv, 'inline shift: returns key+value');
    my @drained = shm_ss_drain $map, 5;
    is(scalar @drained, 10, 'inline drain: returns 5 k/v pairs');
    my $all_valid = 1;
    for (my $i = 0; $i < @drained; $i += 2) {
        $all_valid = 0 unless $drained[$i] =~ /^k\d+$/ && $drained[$i+1] =~ /^v\d+$/;
    }
    ok($all_valid, 'inline drain: all drained strings valid');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $n = $map->set_multi('a', 'A', 'bb', 'BB', 'ccc', 'CCC', 'long_key_here', 'long_val_here');
    is($n, 4, 'set+get_multi roundtrip: set_multi count');
    my @vals = $map->get_multi('a', 'bb', 'ccc', 'long_key_here', 'missing');
    is($vals[0], 'A', 'set+get_multi roundtrip: inline key+val');
    is($vals[1], 'BB', 'set+get_multi roundtrip: inline');
    is($vals[2], 'CCC', 'set+get_multi roundtrip: inline');
    is($vals[3], 'long_val_here', 'set+get_multi roundtrip: arena key+val');
    ok(!defined $vals[4], 'set+get_multi roundtrip: missing undef');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "short", "val";
    shm_ss_put $map, "longkey12345", "longval12345";
    my $pid = fork;
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::SS->new($path, 1000);
        my $v1 = shm_ss_get $child, "short";
        my $v2 = shm_ss_get $child, "longkey12345";
        POSIX::_exit(($v1 eq "val" && $v2 eq "longval12345") ? 0 : 1);
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'cross-process inline: child reads inline+arena strings correctly');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "", "empty_key";
    shm_ss_put $map, "empty_val", "";
    shm_ss_put $map, "", "";
    is((shm_ss_get $map, ""), "", 'empty string: empty key → empty val');
    is((shm_ss_get $map, "empty_val"), "", 'empty string: normal key → empty val');
    my $e = shm_ss_exists $map, "";
    ok($e, 'empty string: exists returns true');
    my $sz = shm_ss_size $map;
    is($sz, 2, 'empty string: size correct');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 10000, 100, 0);
    shm_ss_put $map, "k$_", "v$_" for 1..150;
    my $sz = shm_ss_size $map;
    is($sz, 100, 'LRU inline eviction: size capped at max_size');
    my $ev = shm_ss_stat_evictions $map;
    ok($ev >= 50, 'LRU inline eviction: evictions occurred');
    my $v = shm_ss_get $map, "k150";
    is($v, "v150", 'LRU inline eviction: recent key survives');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);
    shm_ii_put $map, $_, $_ for 1..50;
    Time::HiRes::sleep(2.2);
    my $flushed = shm_ii_flush_expired $map;
    is($flushed, 50, 'flush_expired: all 50 entries flushed');
    my $sz = shm_ii_size $map;
    is($sz, 0, 'flush_expired: size is 0 after flush');
    my $ex = shm_ii_stat_expired $map;
    is($ex, 50, 'flush_expired: stat_expired counts all 50');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);
    shm_ii_put $map, $_, $_ for 1..30;
    Time::HiRes::sleep(2.2);
    my $total = 0;
    my $rounds = 0;
    my $done = 0;
    while (!$done && $rounds < 100) {
        my ($n, $d) = shm_ii_flush_expired_partial $map, 10;
        $total += $n;
        $done = $d;
        $rounds++;
    }
    is($total, 30, 'flush_expired_partial: flushed all 30');
    ok($done, 'flush_expired_partial: done flag set');
    ok($rounds > 1, 'flush_expired_partial: took multiple rounds');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000);
    shm_si_put $map, "counter", 0;
    my $nprocs = 4;
    my $iters = 1000;
    for (1..$nprocs) {
        my $pid = fork;
        if ($pid == 0) {
            my $child = Data::HashMap::Shared::SI->new($path, 1000);
            shm_si_incr $child, "counter" for 1..$iters;
            POSIX::_exit(0);
        }
    }
    while (wait() > 0) {}
    my $v = shm_si_get $map, "counter";
    is($v, $nprocs * $iters, 'concurrent writers SI: atomic incr correct');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..20;
    my $cur1 = shm_ii_cursor $map;
    my ($k1, $v1) = shm_ii_cursor_next $cur1;
    ok(defined $k1, 'cursor nesting: first cursor gets entry');
    my $cur2 = shm_ii_cursor $map;
    my ($k2, $v2) = shm_ii_cursor_next $cur2;
    ok(defined $k2, 'cursor nesting: second cursor gets entry');
    my $count1 = 1;
    while (my ($k, $v) = shm_ii_cursor_next $cur1) { $count1++; }
    my $count2 = 1;
    while (my ($k, $v) = shm_ii_cursor_next $cur2) { $count2++; }
    is($count1, 20, 'cursor nesting: cursor1 visits all');
    is($count2, 20, 'cursor nesting: cursor2 visits all');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ for 1..50;
    my @removed;
    while (my ($k, $v) = shm_ii_each $map) {
        if ($k % 2 == 0) {
            shm_ii_remove $map, $k;
            push @removed, $k;
        }
    }
    ok(scalar @removed > 0, 'remove during each: some removed');
    my $sz = shm_ii_size $map;
    is($sz, 50 - scalar @removed, 'remove during each: size correct');
    my $gone = 1;
    for (@removed) { $gone = 0 if shm_ii_exists $map, $_; }
    ok($gone, 'remove during each: removed keys gone');
    my $remain = 1;
    for (1..50) { next if $_ % 2 == 0; $remain = 0 unless shm_ii_exists $map, $_; }
    ok($remain, 'remove during each: odd keys survive');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100);
    my $ok1 = shm_ii_reserve $map, 50;
    ok($ok1, 'reserve: within max succeeds');
    my $ok2 = shm_ii_reserve $map, 200;
    ok(!$ok2, 'reserve: beyond max_entries fails');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 200);
    my $long = "x" x 500;
    my $filled = 0;
    for (1..200) {
        my $ok = shm_ss_put $map, "longkey_$_" . ("z" x 50), $long;
        last unless $ok;
        $filled++;
    }
    ok($filled > 0, "arena exhaustion: filled $filled long entries");
    my $ok = shm_ss_put $map, "tiny", "val";
    ok($ok, 'arena exhaustion: inline put succeeds despite full arena');
    is((shm_ss_get $map, "tiny"), "val", 'arena exhaustion: inline get works');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $utf_key = "\x{e9}";
    my $utf_val = "\x{263a}";
    utf8::encode($utf_key);
    utf8::encode($utf_val);
    my $ukey = "caf\x{e9}";
    my $uval = "hi\x{2603}";
    shm_ss_put $map, $ukey, $uval;
    my $got = shm_ss_get $map, $ukey;
    is($got, $uval, 'UTF-8 inline: roundtrip short UTF-8 strings');
    ok(utf8::is_utf8($got), 'UTF-8 inline: UTF-8 flag preserved');
    my $long_utf = "\x{2603}" x 10;
    shm_ss_put $map, "snowmen", $long_utf;
    my $got_utf = shm_ss_get $map, "snowmen";
    is($got_utf, $long_utf, 'UTF-8 arena: longer UTF-8 roundtrip');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "key_$_", "val_$_" for 1..50;
    my $cur = shm_ss_cursor $map;
    my $found = shm_ss_cursor_seek $cur, "key_25";
    ok($found, 'cursor seek SS: found target key');
    my ($k, $v) = shm_ss_cursor_next $cur;
    is($k, "key_25", 'cursor seek SS: positioned at correct key');
    is($v, "val_25", 'cursor seek SS: correct value');
    my $nf = shm_ss_cursor_seek $cur, "nonexistent";
    ok(!$nf, 'cursor seek SS: nonexistent key returns false');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    my $old1 = $map->swap(1, 100);
    ok(!defined $old1, 'swap new key: returns undef');
    is((shm_ii_get $map, 1), 100, 'swap new key: value stored');
    my $old2 = $map->swap(1, 200);
    is($old2, 100, 'swap existing key: returns old value');
    is((shm_ii_get $map, 1), 200, 'swap existing key: value updated');
    my $path2 = tmpfile();
    my $ssm = Data::HashMap::Shared::SS->new($path2, 1000);
    my $o1 = $ssm->swap("k", "v1");
    ok(!defined $o1, 'swap SS new: returns undef');
    my $o2 = $ssm->swap("k", "v2");
    is($o2, "v1", 'swap SS existing: returns old value');
    unlink $path;
    unlink $path2;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 1;
    undef $map;
    my $died = 0;
    eval { Data::HashMap::Shared::SS->new($path, 1000); };
    $died = 1 if $@;
    ok($died, 'variant mismatch: opening II file as SS croaks');
    like($@, qr/variant/i, 'variant mismatch: error mentions variant');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 4, 1000, 100);
    shm_ii_put $map, $_, $_ for 1..600;
    my $sz = shm_ii_size $map;
    ok($sz <= 400, "sharded LRU: size capped ($sz <= 400)");
    my $ev = shm_ii_stat_evictions $map;
    ok($ev > 0, "sharded LRU: evictions occurred ($ev)");
    my $v = shm_ii_get $map, 600;
    is($v, 600, 'sharded LRU: most recent key survives');
    unlink "$path.$_" for 0..3;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 10000);
    shm_ii_put $map, $_, $_ for 1..500;
    shm_ii_remove $map, $_ for 1..490;
    my $tb = shm_ii_tombstones $map;
    ok($tb > 0, "tombstone compaction: tombstones present ($tb)");
    # exhausting each() runs the deferred shrink/compact
    my $count = 0;
    while (my ($k, $v) = shm_ii_each $map) { $count++; }
    is($count, 10, 'tombstone compaction: each sees 10 remaining');
    my $tb_after = shm_ii_tombstones $map;
    ok($tb_after <= $tb, "tombstone compaction: tombstones not increased ($tb_after <= $tb)");
    my $ok = 1;
    for (491..500) { my $v = shm_ii_get $map, $_; $ok = 0 unless defined $v && $v == $_; }
    ok($ok, 'tombstone compaction: remaining 10 keys intact');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 100000);
    shm_ii_put $map, $_, $_ for 1..2000;
    my $cap_full = shm_ii_capacity $map;
    ok($cap_full >= 2000, "table shrink: capacity after insert ($cap_full)");
    shm_ii_remove $map, $_ for 1..1900;
    # exhausting each() runs the deferred shrink
    while (my ($k, $v) = shm_ii_each $map) {}
    my $cap_after = shm_ii_capacity $map;
    ok($cap_after < $cap_full, "table shrink: capacity shrank ($cap_after < $cap_full)");
    my $sz = shm_ii_size $map;
    is($sz, 100, 'table shrink: size correct');
    my $ok = 1;
    for (1901..2000) { my $v = shm_ii_get $map, $_; $ok = 0 unless defined $v && $v == $_; }
    ok($ok, 'table shrink: remaining 100 keys intact');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    my $v1 = shm_ss_get_or_set $map, "hello", "world";
    is($v1, "world", 'get_or_set SS: inserts default');
    my $v2 = shm_ss_get_or_set $map, "hello", "other";
    is($v2, "world", 'get_or_set SS: returns existing, ignores default');
    my $v3 = shm_ss_get_or_set $map, "a", "b";
    is($v3, "b", 'get_or_set SS: inline key+val');
    my $v4 = shm_ss_get_or_set $map, "long_key_value_test", "long_default_value_here";
    is($v4, "long_default_value_here", 'get_or_set SS: arena key+val');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 30);
    my $v = shm_ii_incr $map, 42;
    is($v, 1, 'incr new on TTL: returns 1');
    my $rem = shm_ii_ttl_remaining $map, 42;
    ok($rem > 0 && $rem <= 30, 'incr new on TTL: new entry gets default TTL');
    my $v2 = shm_ii_incr_by $map, 99, 10;
    is($v2, 10, 'incr_by new on TTL: returns delta');
    my $rem2 = shm_ii_ttl_remaining $map, 99;
    ok($rem2 > 0, 'incr_by new on TTL: gets TTL');
    unlink $path;
}

{
    my $path = tmpfile();
    my $m1 = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $m1, 1, 100;
    my $m2 = Data::HashMap::Shared::II->new($path, 1000);
    my $v = shm_ii_get $m2, 1;
    is($v, 100, 'two handles: second handle sees first writes');
    shm_ii_put $m2, 2, 200;
    my $v2 = shm_ii_get $m1, 1;
    my $sz1 = shm_ii_size $m1; my $sz2 = shm_ii_size $m2;
    is($sz1, $sz2, 'two handles: size agrees');
    my $v3 = shm_ii_get $m1, 2;
    is($v3, 200, 'two handles: first handle sees second writes');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($path, 16, 1000);
    shm_ii_put $map, $_, $_ * 3 for 1..500;
    my $lsz = shm_ii_size $map;
    is($lsz, 500, 'large shards: size correct');
    my $ok = 1;
    for (1..500) { my $v = shm_ii_get $map, $_; $ok = 0 unless defined $v && $v == $_ * 3; }
    ok($ok, 'large shards: all 500 entries retrievable');
    my $cur = shm_ii_cursor $map;
    my $count = 0;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { $count++; }
    is($count, 500, 'large shards: cursor visits all 500 across 16 shards');
    shm_ii_clear $map;
    my $csz = shm_ii_size $map;
    is($csz, 0, 'large shards: clear works');
    unlink "$path.$_" for 0..15;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 16);
    my $inserted = 0;
    for (1..100) {
        my $ok = shm_ii_put $map, $_, $_;
        $inserted++ if $ok;
    }
    ok($inserted < 100, "full table: not all 100 inserted ($inserted)");
    ok($inserted >= 10, "full table: at least 10 inserted ($inserted)");
    my $readable = 0;
    for (1..$inserted) {
        $readable++ if defined shm_ii_get $map, $_;
    }
    ok($readable > 0, "full table: $readable entries readable");
    unlink $path;
}

SKIP: {
    my $path = tmpfile();
    my $m = eval { Data::HashMap::Shared::II->new($path, 3_000_000_000) };
    skip "cannot map a 36 GB sparse file here: $@", 2 unless $m;
    is($m->max_entries, 1610612736, 'a request beyond the table limit reports 1610612736');
    ok($m->put(1, 1) && $m->get(1) == 1, '  ... and the map works');
    undef $m;
    unlink $path;
}

done_testing;
