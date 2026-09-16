use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# Compaction clears the class free lists before it moves anything, so every gap
# it then declines to close has to be handed back.  A block is only slid when
# its destination lies wholly below its source; where a small hole sits under a
# larger live block that never holds, and if those gaps are not relisted the
# arena silently loses space it could already allocate -- capacity that a map
# without compaction at all would still have.
#
# The layout below makes every block stuck: 128-class holes under 512-class
# blocks.

my $dir = tempdir(CLEANUP => 1);

sub build {                      # fill alternating, then free every small one
    my ($path) = @_;
    my $m = Data::HashMap::Shared::SS->new($path, 4096, 0, 0, 0, 65536);
    my ($i, @small) = (0);
    while (1) {
        last unless $m->put("s$i", 'a' x 100);          # 128 class
        push @small, "s$i";
        last unless $m->put("b$i", 'c' x 300);          # 512 class
        $i++;
    }
    $m->remove($_) for @small;
    return ($m, scalar @small, $i);
}

{
    my ($m, $freed, $bigs) = build("$dir/auto.shm");
    cmp_ok $freed, '>', 50, 'the fixture frees a useful number of small blocks';
    my $used = $m->arena_used;

    # Whatever compaction the refused stores in build() armed has already run by
    # the first insert here, so this measures the state it left behind.
    my ($ok, $fail) = (0, 0);
    for my $n (1 .. $freed) { $m->put("p$n", 'a' x 100) ? $ok++ : $fail++ }
    is $fail, 0, 'every freed block is still allocatable after compaction'
        or diag "ok=$ok fail=$fail used=$used -> " . $m->arena_used;
    is $ok, $freed, '  ... all of them, not just the bump remainder';

    my @bad = grep { ($m->get("b$_") // '') ne 'c' x 300 } 0 .. $bigs - 1;
    is_deeply \@bad, [], '  ... and the blocks that stayed put are unharmed';
}

{
    my ($m, $freed, $bigs) = build("$dir/explicit.shm");
    my $gained = $m->compact;
    # Against arena_used this could not fail: the return is before-minus-bump,
    # and the bump never goes below the reserved first offset.  The claim is
    # that a layout where nothing can slide gathers almost none of its free
    # space, so compare it to that free space.
    cmp_ok $gained, '<', $freed * 128 / 4,
        'an explicit compact on a stuck layout reclaims almost none of the free space';
    my ($ok, $fail) = (0, 0);
    for my $n (1 .. $freed) { $m->put("q$n", 'a' x 100) ? $ok++ : $fail++ }
    is $fail, 0, '  ... and still gives back every block it could not slide';
    my @bad = grep { ($m->get("b$_") // '') ne 'c' x 300 } 0 .. $bigs - 1;
    is_deeply \@bad, [], '  ... with the stuck blocks unharmed';
}

# The gap must come back as the blocks that were freed there, not re-cut into
# the largest class that fits.  Nothing here splits a block, so handing a run of
# small holes back as one big block destroys the capacity instead of preserving
# it.  The case above cannot catch that: its holes are isolated, one small block
# between two large ones, so there is no run to merge.  This one frees a
# contiguous run under a block that cannot slide.
# Sixteen 16-byte blocks under a 512-byte anchor: the gap is 256 bytes, smaller
# than the block above it, so the anchor cannot slide and the run has to be
# relisted -- and a relist that merges hands back one 256-byte block, which no
# 16-byte request can use because nothing splits.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/run.shm", 8192, 0, 0, 0, 65536);
    my $tiny   = 'a' x 10;                      # 16 class
    my $anchor = 'z' x 400;                     # 512 class
    my @tinies;
    my ($i, $g) = (0, 0);       # a list assignment into (@a, $i, $g) leaves both undef
    GROUP: while ($m->arena_used + 2048 < $m->arena_cap) {
        for (1 .. 16) {
            my $key = "t$i"; $i++;              # <= 7 bytes: key inlines
            last GROUP unless $m->put($key, $tiny);
            push @tinies, $key;
        }
        last unless $m->put("A$g", $anchor);
        $g++;
    }
    cmp_ok $g, '>', 3, 'the fixture built several 256B runs under 512B anchors';

    $m->remove($_) for @tinies;
    my $gained = $m->compact;

    my ($ok, $fail) = (0, 0);
    for my $n (1 .. scalar @tinies) { $m->put("n$n", $tiny) ? $ok++ : $fail++ }
    cmp_ok $ok, '>=', @tinies * 0.9,
        'a freed run comes back as its own class, not merged into one big block'
        or diag sprintf 'stored %d of %d freed (compact returned %d)', $ok, scalar @tinies, $gained;
    is $m->get("A0"), $anchor, '  ... and a block that could not slide is unharmed';
}

# A layout that can slide must still actually reclaim, or the relist would have
# been achieved by simply never compacting.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/slide.shm", 4096, 0, 0, 0, 65536);
    my $i = 0;
    while ($m->arena_used + 1024 < $m->arena_cap) {
        $m->put(sprintf('u%05d', $i++), 'u' x 100) or last;
    }
    $m->remove(sprintf 'u%05d', $_) for grep { $_ % 2 } 0 .. $i - 1;
    my $before = $m->arena_used;
    cmp_ok $m->compact, '>', 0, 'a uniform layout does slide, and reclaims bump';
    cmp_ok $m->arena_used, '<', $before, '  ... visibly';
}

# Repeated cycles must not bleed capacity.  A block that slides out of a gap
# vacates its source, and that source was live when the free lists were
# snapshotted, so nothing in the snapshot can give it back.  Left unhandled it
# accumulates: measured 22% of the entries gone after a dozen cycles, with the
# stranded total climbing every round.  Both cases above are blind to it,
# because in each of them nothing slides.
{
    my $m = Data::HashMap::Shared::SS->new("$dir/cycles.shm", 8192, 0, 0, 0, 65536);
    my $tiny   = 'a' x 10;                      # 16 class
    my $anchor = 'Z' x 4000;                    # 4096 class: these cannot slide
    my (%live, $n);
    for my $g (0 .. 7) {
        for (1 .. 255) { my $k = 't' . $n++; $m->put($k, $tiny) or last; $live{$k} = 1 }
        $m->put("A$g", $anchor) or last;
    }
    my $start = scalar keys %live;
    cmp_ok $start, '>', 1500, 'the cycle fixture fills the arena under stuck anchors';

    # Free a small scattered subset each round, so the tinies that slide do so
    # into the holes and vacate sources inside a gap under an anchor.
    srand 7;
    for my $cycle (1 .. 12) {
        my @k = sort keys %live;
        for (1 .. 40) {
            last unless @k;
            my $victim = splice @k, int(rand @k), 1;
            $m->remove($victim); delete $live{$victim};
        }
        $m->compact;
        while (1) { my $k = 't' . $n++; last unless $m->put($k, $tiny); $live{$k} = 1 }
    }
    cmp_ok scalar(keys %live), '>=', $start * 0.95,
        'repeated compaction does not bleed capacity cycle after cycle'
        or diag sprintf 'started with %d tinies, ended with %d', $start, scalar keys %live;
}

done_testing;
