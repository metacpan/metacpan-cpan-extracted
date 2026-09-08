use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;

sub tmpfile { File::Temp::tempnam(File::Spec->tmpdir, 'shm_test') . '.shm' }

# Basic cursor iteration (II)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    shm_ii_put $map, $_, $_ * 10 for 1..5;

    my $cur = shm_ii_cursor $map;
    isa_ok($cur, 'Data::HashMap::Shared::II::Cursor');

    my %seen;
    while (my ($k, $v) = shm_ii_cursor_next $cur) {
        $seen{$k} = $v;
    }
    is(scalar keys %seen, 5, 'cursor visited all entries');
    is($seen{3}, 30, 'cursor returned correct values');

    unlink $path;
}

# Cursor method API
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;

    my $cur = $map->cursor();
    isa_ok($cur, 'Data::HashMap::Shared::II::Cursor');

    my ($k, $v) = $cur->next();
    is($k, 1, 'method cursor->next key');
    is($v, 10, 'method cursor->next value');

    my @empty = $cur->next();
    is(scalar @empty, 0, 'exhausted cursor returns empty');

    unlink $path;
}

# Cursor reset
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, 1, 10;
    shm_ii_put $map, 2, 20;

    my $cur = shm_ii_cursor $map;

    my @first;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { push @first, $k }
    is(scalar @first, 2, 'first pass');

    shm_ii_cursor_reset $cur;
    my @second;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { push @second, $k }
    is(scalar @second, 2, 'second pass after reset');

    unlink $path;
}

# Multiple cursors on same map
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..3;

    my $c1 = shm_ii_cursor $map;
    my $c2 = shm_ii_cursor $map;

    my @c1_keys;
    while (my ($k, $v) = shm_ii_cursor_next $c1) { push @c1_keys, $k }

    my @c2_keys;
    while (my ($k, $v) = shm_ii_cursor_next $c2) { push @c2_keys, $k }

    is(scalar @c1_keys, 3, 'cursor 1 visited all');
    is(scalar @c2_keys, 3, 'cursor 2 visited all');

    # Same keys in both
    is_deeply([sort @c1_keys], [sort @c2_keys], 'cursors see same data');

    unlink $path;
}

# Remove during each (safe iteration)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..100;

    my @removed;
    while (my ($k, $v) = shm_ii_each $map) {
        if ($k % 2 == 0) {
            shm_ii_remove $map, $k;
            push @removed, $k;
        }
    }

    ok(scalar @removed > 0, 'removed entries during each');
    is(shm_ii_size $map, 50, '50 entries remain after removing evens');

    for my $k (@removed) {
        ok(!defined(shm_ii_get $map, $k), "removed key $k is gone")
            or last;  # avoid flooding
    }

    unlink $path;
}

# Remove during cursor iteration
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ * 10 for 1..50;

    my $cur = shm_ii_cursor $map;
    my @removed;
    while (my ($k, $v) = shm_ii_cursor_next $cur) {
        if ($k % 3 == 0) {
            shm_ii_remove $map, $k;
            push @removed, $k;
        }
    }

    ok(scalar @removed > 0, 'removed during cursor');
    for my $k (@removed) {
        ok(!defined(shm_ii_get $map, $k), "cursor-removed key $k is gone")
            or last;
    }

    unlink $path;
}

# iter_reset mid-iteration
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ for 1..10;

    my $count = 0;
    while (my ($k, $v) = shm_ii_each $map) {
        $count++;
        last if $count == 3;
    }
    shm_ii_iter_reset $map;

    my @all;
    while (my ($k, $v) = shm_ii_each $map) {
        push @all, $k;
    }
    is(scalar @all, 10, 'iter_reset allows full re-scan');

    unlink $path;
}

# SS cursor (string key + string value)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SS->new($path, 1000);
    shm_ss_put $map, "key$_", "val$_" for 1..5;

    my $cur = shm_ss_cursor $map;
    my %seen;
    while (my ($k, $v) = shm_ss_cursor_next $cur) {
        $seen{$k} = $v;
    }
    is(scalar keys %seen, 5, 'SS cursor visited all');
    is($seen{key3}, 'val3', 'SS cursor correct values');

    unlink $path;
}

# SI cursor (string key + int value)
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::SI->new($path, 1000);
    shm_si_put $map, "k$_", $_ for 1..5;

    my $cur = shm_si_cursor $map;
    my %seen;
    while (my ($k, $v) = shm_si_cursor_next $cur) {
        $seen{$k} = $v;
    }
    is(scalar keys %seen, 5, 'SI cursor visited all');
    is($seen{k4}, 4, 'SI cursor correct value');

    unlink $path;
}

# Cursor DESTROY mid-iteration
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);
    shm_ii_put $map, $_, $_ for 1..10;

    {
        my $cur = shm_ii_cursor $map;
        shm_ii_cursor_next $cur;  # partial iteration
        # $cur goes out of scope here — DESTROY should clean up iterating count
    }

    # Map should still work fine
    shm_ii_put $map, 100, 1000;
    is(shm_ii_get $map, 100, 1000, 'map works after cursor DESTROY');

    unlink $path;
}

# Deferred compaction fires after iteration ends
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000);

    # Insert enough to grow table
    shm_ii_put $map, $_, $_ for 1..200;

    # Remove most entries during iteration — deferred shrink/compact
    my $removed = 0;
    while (my ($k, $v) = shm_ii_each $map) {
        shm_ii_remove $map, $k;
        $removed++;
    }
    is($removed, 200, 'removed all during iteration');
    is(shm_ii_size $map, 0, 'size is 0 after mass remove');

    # Verify map is functional after deferred flush
    shm_ii_put $map, 1, 42;
    is(shm_ii_get $map, 1, 42, 'map functional after deferred flush');

    unlink $path;
}

# Cursor with LRU
{
    my $path = tmpfile();
    my $map = Data::HashMap::Shared::II->new($path, 1000, 10);  # max_size=10

    shm_ii_put $map, $_, $_ * 10 for 1..10;

    my $cur = shm_ii_cursor $map;
    my $count = 0;
    while (my ($k, $v) = shm_ii_cursor_next $cur) {
        $count++;
    }
    is($count, 10, 'cursor with LRU visits all');

    unlink $path;
}

# A seek that finds nothing must leave the iteration alone.  It used to switch
# shard (and reset iter_pos) before probing, so a failed seek cost a sharded
# pass its position, and rewound an exhausted cursor to a whole second pass.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $prefix = File::Spec->catfile($dir, 'seekshard');
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, 8, 40_000);
    $map->put($_, $_) for 1 .. 40;

    my $missing = 1;
    $missing++ while defined $map->get($missing);

    my $cur = shm_ii_cursor $map;
    my (%seen, $yields);
    $yields = 0;
    while (my ($k) = shm_ii_cursor_next $cur) {
        $yields++;
        $seen{$k}++;
        last if $yields > 200;          # a repositioning seek used to loop here
        ok !(shm_ii_cursor_seek $cur, $missing), 'seek of a missing key is false'
            if $yields == 1;
        shm_ii_cursor_seek $cur, $missing;
    }
    is($yields, 40, 'a failed seek leaves a sharded iteration intact');
    is(scalar(keys %seen), 40, '  ... visiting every key exactly once');
    is(scalar(grep { $seen{$_} > 1 } keys %seen), 0, '  ... with no repeats');
}

{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'seekplain.shm');
    my $map = Data::HashMap::Shared::II->new($path, 64);
    $map->put($_, $_) for 1 .. 10;

    my $cur = shm_ii_cursor $map;
    my $first = 0;
    $first++ while (shm_ii_cursor_next $cur)[0];
    is($first, 10, 'first pass visits every key');

    ok !(shm_ii_cursor_seek $cur, 999_999), 'seek of a missing key is false';
    my $second = 0;
    $second++ while (shm_ii_cursor_next $cur)[0];
    is($second, 0, 'a failed seek does not rewind an exhausted cursor');
}

# keys/values/items walk states[] directly; each and the cursor go through the
# SIMD live-slot scan.  Two implementations of the same traversal, and nothing
# compared them -- so a scan that skipped one slot per group was invisible to
# keys() while each() silently lost entries.  A sparse table is what exposes it:
# in a dense one a neighbour lands in the skipped position and masks the gap.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $path = File::Spec->catfile($dir, 'sparse.shm');
    my $map = Data::HashMap::Shared::II->new($path, 100_000);
    $map->reserve(50_000);                    # many slots, few entries
    my $N = 300;
    $map->put($_, $_ * 3) for 1 .. $N;
    cmp_ok($map->capacity, '>=', 8 * $N, 'sparse table: far more slots than entries');

    my @by_keys = sort { $a <=> $b } $map->keys;
    my @by_each;
    while (my ($k, $v) = shm_ii_each $map) { push @by_each, $k }
    @by_each = sort { $a <=> $b } @by_each;
    my $cur = shm_ii_cursor $map;
    my @by_cursor;
    while (my ($k, $v) = shm_ii_cursor_next $cur) { push @by_cursor, $k }
    @by_cursor = sort { $a <=> $b } @by_cursor;

    is(scalar(@by_keys),   $N, 'keys() sees every entry');
    is(scalar(@by_each),   $N, 'each() sees every entry');
    is(scalar(@by_cursor), $N, 'the cursor sees every entry');
    is_deeply(\@by_each,   \@by_keys, 'each() agrees with keys()');
    is_deeply(\@by_cursor, \@by_keys, 'the cursor agrees with keys()');
}

done_testing;
