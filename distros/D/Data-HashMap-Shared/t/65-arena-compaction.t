use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::II;

# Arena blocks are exact power-of-two classes that are never split or merged, so
# freeing any number of small ones never yields a large one and the bump never
# comes back on its own.  Compaction slides the live blocks together, which is
# the only way a fragmented arena serves a class it has no free block for.

my $dir = tempdir(CLEANUP => 1);

sub filled {                     # a map fragmented by removing every other key
    my ($path, $cap) = @_;
    my $m = Data::HashMap::Shared::SS->new($path, 8192, 0, 0, 0, $cap);
    my (%want, $i);
    # Stop short of a refusal: a refused store arms the automatic compaction,
    # and these cases want to observe the refusal itself.
    while ($m->arena_used + 1024 < $m->arena_cap) {
        my $k = sprintf 'key%06d', $i++;
        my $v = 'v' x (100 + ($i % 5) * 30);
        $m->put($k, $v) or last;
        $want{$k} = $v;
    }
    for my $k (sort keys %want) {
        next if (substr($k, 3) % 2) == 0;
        $m->remove($k);
        delete $want{$k};
    }
    return ($m, \%want);
}

{
    my ($m, $want) = filled("$dir/frag.shm", 65536);
    cmp_ok scalar(keys %$want), '>', 50, 'the map holds a useful number of entries';
    my $used = $m->arena_used;
    cmp_ok $used, '>', $m->arena_cap * 0.9, 'removing half the entries does not lower the bump';

    my $big = 'w' x 900;                        # 1024 class: nothing freed serves it
    ok !$m->put('PRE', $big), 'a class with no free block is refused while fragmented';

    my $freed = $m->compact;
    cmp_ok $freed, '>', $used / 4, 'compaction reclaims the holes'
        or diag "freed=$freed used=$used";
    is $m->arena_used, $used - $freed, '  ... and that is exactly what arena_used drops by';
    is $m->size, scalar keys %$want, '  ... without losing an entry';

    my @bad = grep { ($m->get($_) // '') ne $want->{$_} } sort keys %$want;
    is_deeply \@bad, [], '  ... and every survivor still reads back byte for byte';

    is $m->compact, 0, 'compacting again reclaims nothing';

    my $n = 0;
    for my $j (1 .. 20) { last unless $m->put("BIG$j", $big); $n++ }
    cmp_ok $n, '>', 10, 'the reclaimed space serves a size class nothing had freed';
    is $m->get('BIG1'), $big, '  ... storing the value intact';
    my @bad2 = grep { ($m->get($_) // '') ne $want->{$_} } sort keys %$want;
    is_deeply \@bad2, [], '  ... and the moved entries survived being written around';
}

# The automatic trigger: a refused store makes the next insert compact first.
{
    my ($m, $want) = filled("$dir/auto.shm", 65536);
    my $big = 'w' x 900;
    my $used = $m->arena_used;
    ok !$m->put(auto1 => $big), 'the store that finds no block of its class is refused';
    ok $m->put(auto2 => $big), '  ... and the next insert compacts first, so it fits';
    cmp_ok $m->arena_used, '<', $used, '  ... which is visible as the bump coming back';
    is $m->get('auto2'), $big, '  ... with the value intact';
    is $m->get('auto1'), undef, '  ... and the refused one left nothing behind';
    my @bad = grep { ($m->get($_) // '') ne $want->{$_} } sort keys %$want;
    is_deeply \@bad, [], '  ... and nothing else disturbed';
}

# A workload that only ever updates existing keys reaches no insert at all, so
# the reclaim has to sit on the overwrite path too or such a map never compacts.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/update.shm", 8192, 0, 0, 0, 65536);
    my ($i, @all) = (0);
    while ($m->arena_used + 320 < $m->arena_cap) {   # spend the bump
        my $k = sprintf 'key%06d', $i++;
        $m->put($k, 'v' x 200) or last;              # 256 class
        push @all, $k;
    }
    $m->remove($all[$_]) for grep { $_ % 2 } 0 .. $#all;
    my @left = @all[grep { !($_ % 2) } 0 .. $#all];
    my $held = $m->size;
    cmp_ok scalar @left, '>', 40, 'holes exist, and the bump is spent';

    # Grow a subset into the 1024 class. Nothing here inserts a key, so without
    # a reclaim on the overwrite path the freed space is unreachable and every
    # one of these fails.
    my @grow = @left[0 .. 24];
    my ($ok, $fail) = (0, 0);
    for my $round (1 .. 3) {
        for my $k (@grow) { $m->put($k, 'w' x 900) ? $ok++ : $fail++ }
    }
    is $m->size, $held, 'the key set never changed: these are all overwrites';
    my @grown = grep { ($m->get($_) // '') eq 'w' x 900 } @grow;
    cmp_ok scalar @grown, '>=', 20, 'an update-only workload reaches the freed space'
        or diag "grown=" . @grown . " ok=$ok fail=$fail used=" . $m->arena_used;
    my @spoiled = grep { ($m->get($_) // '') ne 'v' x 200 } @left[25 .. $#left];
    is_deeply \@spoiled, [], '  ... without disturbing the entries it did not touch';
}

# Inline strings live in the node, not the arena, and must not be touched.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/inline.shm", 512, 0, 0, 0, 65536);
    $m->put("k$_", "v$_") for 1 .. 100;         # all <= 7 bytes: inline
    $m->put(long => 'L' x 500);
    $m->remove('long');
    my $freed = $m->compact;
    cmp_ok $freed, '>', 0, 'an arena holding nothing live resets whole';
    is $m->arena_used, 16, '  ... back to the reserved first offset';
    is $m->size, 100, '  ... with the inline entries still counted';
    my @bad = grep { ($m->get("k$_") // '') ne "v$_" } 1 .. 100;
    is_deeply \@bad, [], '  ... and readable';
}

# UTF-8 keys and values keep their flag across a move.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/utf8.shm", 512, 0, 0, 0, 65536);
    my $k = "\x{263A}" x 20;
    my $v = "\x{4F60}\x{597D}" x 40;
    $m->put($k, $v);
    $m->put(pad => 'p' x 500);
    $m->remove('pad');
    $m->compact;
    is $m->get($k), $v, 'a utf8 value survives compaction';
    ok utf8::is_utf8($m->get($k)), '  ... with its flag';
    my ($got) = $m->keys;
    is $got, $k, '  ... and so does the key';
}

# An int-keyed, int-valued map has no arena at all.
{
    my $m = Data::HashMap::Shared::II->new("$dir/ii.shm", 512);
    $m->put($_, $_ * 2) for 1 .. 50;
    is $m->compact, 0, 'compacting a map with no arena is a no-op';
    is $m->size, 50, '  ... and changes nothing';
}

# Frozen maps refuse it like any other mutation.
{
    my $path = "$dir/frozen.shm";
    my $m = Data::HashMap::Shared::SS->new($path, 512, 0, 0, 0, 65536);
    $m->put(a => 'x' x 100);
    $m->freeze;
    my $ro = Data::HashMap::Shared::SS->new_readonly($path);
    ok !eval { $ro->compact; 1 }, 'compact croaks on a frozen map';
    like $@, qr/frozen/, '  ... saying so';
}

done_testing;
