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

done_testing;
