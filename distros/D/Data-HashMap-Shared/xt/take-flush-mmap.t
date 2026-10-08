use strict;
use warnings;
use Test::More;
use Time::HiRes ();

plan skip_all => "AUTHOR_TESTING not set" unless $ENV{AUTHOR_TESTING};
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::IS;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, 42, 100;
    is(shm_ii_size $map, 1, 'II size before take');

    my $val = shm_ii_take $map, 42;
    is($val, 100, 'II take returns correct value');
    is(shm_ii_size $map, 0, 'II size after take');
    ok(!defined(shm_ii_get $map, 42), 'II key gone after take');

    ok(!defined(shm_ii_take $map, 999), 'II take undef for missing key');

    shm_ii_put $map, 10, 200;
    is($map->take(10), 200, 'II method take');
    is(shm_ii_size $map, 0, 'II size after method take');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    shm_ss_put $map, "hello", "world";
    my $val = shm_ss_take $map, "hello";
    is($val, "world", 'SS take returns correct value');
    is(shm_ss_size $map, 0, 'SS size after take');
    ok(!defined(shm_ss_take $map, "hello"), 'SS take undef after already taken');

    shm_ss_put $map, "key", "\x{263A}";
    my $taken = shm_ss_take $map, "key";
    ok(utf8::is_utf8($taken), 'SS take preserves UTF-8 flag');
    is($taken, "\x{263A}", 'SS take returns correct UTF-8 value');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000);

    shm_si_put $map, "counter", 42;
    my $val = shm_si_take $map, "counter";
    is($val, 42, 'SI take returns correct value');
    is(shm_si_size $map, 0, 'SI size after take');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::IS->new($path, 1000);

    shm_is_put $map, 7, "seven";
    my $val = shm_is_take $map, 7;
    is($val, "seven", 'IS take returns correct value');
    is(shm_is_size $map, 0, 'IS size after take');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put $map, 1, 10;
    Time::HiRes::sleep(2.2);
    ok(!defined(shm_ii_take $map, 1), 'II take undef for expired key');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put $map, $_, $_ * 10 for 1..10;
    is(shm_ii_size $map, 10, 'size before flush');

    is(shm_ii_flush_expired $map, 0, 'flush_expired returns 0 when nothing expired');
    is(shm_ii_size $map, 10, 'size unchanged after flush with no expired');

    Time::HiRes::sleep(2.2);

    my $flushed = shm_ii_flush_expired $map;
    is($flushed, 10, 'flush_expired returns count of flushed entries');
    is(shm_ii_size $map, 0, 'size 0 after flush');

    shm_ii_put $map, 1, 10;
    Time::HiRes::sleep(2.2);
    is($map->flush_expired(), 1, 'method flush_expired');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    is(shm_ii_flush_expired $map, 0, 'flush_expired 0 on non-TTL map');
    is(shm_ii_size $map, 1, 'entries unchanged on non-TTL map');
    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put $map, 1, 10;
    shm_ii_put_ttl $map, 2, 20, 0;
    shm_ii_put_ttl $map, 3, 30, 60;

    Time::HiRes::sleep(2.2);

    my $flushed = shm_ii_flush_expired $map;
    is($flushed, 1, 'only short-TTL entry flushed');
    is(shm_ii_size $map, 2, 'permanent and long-TTL entries remain');
    ok(!defined(shm_ii_get $map, 1), 'short-TTL entry gone');
    is(shm_ii_get $map, 2, 20, 'permanent entry survives');
    is(shm_ii_get $map, 3, 30, 'long-TTL entry survives');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000, 0, 2);

    shm_ss_put $map, "a", "1";
    shm_ss_put $map, "b", "2";
    Time::HiRes::sleep(2.2);

    my $flushed = shm_ss_flush_expired $map;
    is($flushed, 2, 'SS flush_expired count');
    is(shm_ss_size $map, 0, 'SS size 0 after flush');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put $map, $_, $_ * 10 for 1..50;
    Time::HiRes::sleep(2.2);

    my $total_flushed = 0;
    my $rounds = 0;
    my $done = 0;
    while (!$done) {
        my ($flushed, $d) = shm_ii_flush_expired_partial $map, 10;
        $total_flushed += $flushed;
        $done = $d;
        $rounds++;
    }
    is($total_flushed, 50, 'partial flush expired all 50 entries');
    ok($rounds >= 2, "took multiple rounds: $rounds");
    is(shm_ii_size $map, 0, 'size 0 after partial flush');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 60);

    shm_ii_put $map, $_, $_ for 1..20;

    my ($flushed, $done) = shm_ii_flush_expired_partial $map, 100;
    is($flushed, 0, 'partial: nothing flushed when not expired');
    is($done, 1, 'partial: done=1 when limit >= capacity');
    is(shm_ii_size $map, 20, 'all entries remain');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    my ($flushed, $done) = shm_ii_flush_expired_partial $map, 10;
    is($flushed, 0, 'partial: 0 on non-TTL map');
    is($done, 1, 'partial: done=1 on non-TTL map (trivially complete)');
    unlink $path;
}

# cursor persists across calls
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);

    shm_ii_put $map, $_, $_ for 1..100;
    Time::HiRes::sleep(2.2);

    my ($f1, $d1) = shm_ii_flush_expired_partial $map, 30;
    ok(!$d1, 'first partial pass not done');

    my ($f2, $d2) = shm_ii_flush_expired_partial $map, 30;

    ok($f1 + $f2 > 0, "flushed entries across two passes: $f1 + $f2");

    my ($f3, $d3) = shm_ii_flush_expired_partial $map, 1000;
    is(shm_ii_size $map, 0, 'all entries flushed after full pass');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 0, 2);
    shm_ii_put $map, 1, 10;
    Time::HiRes::sleep(2.2);
    my ($f, $d) = $map->flush_expired_partial(100);
    is($f, 1, 'method flush_expired_partial flushed');
    is($d, 1, 'method flush_expired_partial done');
    unlink $path;
}

# sharded: per-shard cursors; $done is true only once all shards
# complete a cycle
{
    my $prefix = tmpfile();
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, 4, 1000, 0, 1);  # ttl=1s
    $map->put($_, $_) for 1 .. 40;
    Time::HiRes::sleep(1.2);
    my ($total, $done, $calls) = (0, 0, 0);
    while (!$done) {
        my ($n, $d) = $map->flush_expired_partial(8);   # 8 slots per shard per call
        $total += $n; $done = $d;
        last if ++$calls > 5000;
    }
    ok($done, 'sharded flush_expired_partial: done once all shards complete a cycle');
    is($total, 40, 'sharded flush_expired_partial: all expired entries flushed across shards');
    is($map->size, 0, 'sharded: map empty after gradual flush');
    unlink glob "$prefix*";
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    my $sz = shm_ii_mmap_size $map;
    ok($sz > 0, "mmap_size > 0: $sz");

    my $file_sz = -s $path;
    is($sz, $file_sz, 'mmap_size matches file size');

    is($map->mmap_size(), $sz, 'method mmap_size');

    shm_ii_put $map, $_, $_ for 1..500;
    my $sz2 = shm_ii_mmap_size $map;
    is($sz2, $sz, 'mmap_size unchanged after internal table growth');

    unlink $path;
}

{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);

    my $sz = shm_ss_mmap_size $map;
    ok($sz > 0, "SS mmap_size > 0: $sz");
    is($sz, -s $path, 'SS mmap_size matches file size');

    unlink $path;
}

done_testing;
