use strict;
use warnings;
use Test::More;
use Config;
use POSIX ':sys_wait_h';
use File::Temp qw(tempdir);
use Data::SortedSet::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Defense-in-depth for a hostile segment: node indices and index-slot state
# bytes live in peer-writable shared memory.  These tests corrupt the mapping
# through the backing file (MAP_SHARED: immediately visible) and then call the
# write paths in a child process:
#   * F3: a poisoned B+tree child pointer must stop the write paths (insert,
#     delete, merge, underflow) instead of a wild read/write under the lock.
#   * F4: an all-occupied member index must bound the open-addressing probe
#     (and the backward-shift delete scan) by the table size instead of
#     spinning forever under the lock.
#   * F6: add_many must keep the rows array alive across element magic.
# The children run under a parent-side watchdog: the unguarded code spins in
# pure C, where Perl signal handlers never fire, so alarm() cannot be used.

# Shared-memory layout constants (must match sortedset.h; the geometry is
# cross-checked against stats() at runtime).
use constant {
    HEADER_SIZE   => 256,
    READER_SLOTS  => 1024,
    SLOT_SIZE     => 16,
    OCC_BYTES     => 128,
    IDX_SLOT_SIZE => 24,   # int64 member + double score + uint8 state, padded
    IDX_STATE_OFF => 16,
    NODE_SIZE     => 424,
    NODE_CHILDREN => 288,  # offsetof(SsNode, children)
    HDR_ROOT_OFF  => 56,
};

sub index_off { HEADER_SIZE + READER_SLOTS * SLOT_SIZE + OCC_BYTES }   # 16768
sub nodes_off { my ($slots) = @_; (index_off() + $slots * IDX_SLOT_SIZE + 7) & ~7 }

# run a vulnerable snippet in a child; return (reaped?, status)
sub run_child {
    my ($code) = @_;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    unless ($pid) { $code->(); POSIX::_exit(0) }
    my $done; my $deadline = time + 10;
    while (time < $deadline) {
        my $r = waitpid($pid, WNOHANG);
        if ($r == $pid) { $done = 1; last }
        select undef, undef, undef, 0.05;
    }
    if (!$done) { kill 9, $pid; waitpid($pid, 0); }
    return ($done, $?);
}

# --- F4: corrupt all-occupied member index -----------------------------------
{
    my $dir  = tempdir(CLEANUP => 1);
    my $path = "$dir/idx.ss";
    my $z = Data::SortedSet::Shared->new($path, 8);   # index_slots == 16
    $z->add($_, $_ + 0.5) for 1 .. 4;
    my $slots = $z->stats->{index_slots};
    die "test setup: expected 16 index slots, got $slots" unless $slots == 16;

    # Flip every index slot's state byte to "occupied".  Members left as-is
    # (real members 1..4, zeros elsewhere); none equals the probe member 999.
    open my $fh, '+<', $path or die $!;
    for my $i (0 .. $slots - 1) {
        sysseek $fh, index_off() + $i * IDX_SLOT_SIZE + IDX_STATE_OFF, 0 or die $!;
        syswrite $fh, "\x01" or die $!;
    }
    close $fh;

    my ($done, $st) = run_child(sub {
        # Each of these hits an unbounded loop without the fix, in order:
        # ss_idx_find (add's absent-member probe), ss_idx_del's backward-shift
        # scan (remove), ss_idx_find again (exists).
        my $a = $z->add(999, 9.5);        # must fail cleanly (undef), not spin/clobber
        my $r = $z->remove(2);            # present member: bounded shift scan
        my $e = $z->exists(999);          # absent member: bounded probe
        POSIX::_exit(!defined($a) && $r && !$e ? 0 : 7);
    });
    ok $done, 'corrupt full index: add/remove/exist return instead of hanging under the lock';
    SKIP: {
        skip 'child hung and was killed (unbounded probe)', 2 unless $done;
        ok !($st & 127), 'corrupt full index: no crash'
            or diag sprintf('died with signal %d', $st & 127);
        is $st >> 8, 0, 'corrupt full index: add fails cleanly, remove/exist behave'
            or diag sprintf('child exit %d', $st >> 8);
    }
}

# --- F3: corrupt B+tree child pointer on the write paths ---------------------
{
    my $dir  = tempdir(CLEANUP => 1);
    my $path = "$dir/tree.ss";
    my $z = Data::SortedSet::Shared->new($path, 64);
    $z->add($_, $_ + 0.0) for 1 .. 40;
    my $st0 = $z->stats;
    die "test setup: expected an internal root" unless $st0->{height} >= 2;

    open my $fh, '+<', $path or die $!;
    sysseek $fh, HDR_ROOT_OFF, 0 or die $!;
    sysread $fh, my $buf, 4 or die $!;
    my $root = unpack 'V', $buf;
    die "test setup: bad root $root" if $root >= $st0->{node_capacity};

    # Poison the root's children[1] with an index far outside the node pool:
    # dereferencing it is an immediate segfault (~800 GB past the mapping),
    # never a silent in-range read.  With 1..40 inserted in order the leaves
    # are [1..8] [9..16] [17..24] [25..40], so keys in [9,17) descend children[1].
    my $bad = 0x7FFF0000;
    sysseek $fh, nodes_off($st0->{index_slots}) + $root * NODE_SIZE + NODE_CHILDREN + 4, 0 or die $!;
    syswrite $fh, pack('V', $bad) or die $!;
    close $fh;

    my ($done, $st) = run_child(sub {
        $z->remove(12);          # ss_delete_rec descends children[1]
        $z->add(100, 12.5);      # ss_insert_rec descends children[1]
        $z->remove($_) for 1, 2; # underflow in children[0]: ss_fix_underflow/ss_merge touch children[1]
        my $ok = ($z->at_rank(-1) // -1) == 40;   # tree walk over the untouched subtree
        POSIX::_exit($ok ? 0 : 7);
    });
    ok $done, 'corrupt child index: write paths return instead of hanging';
    SKIP: {
        skip 'child hung and was killed', 2 unless $done;
        ok !($st & 127), 'corrupt child index: no wild read/write under the write lock'
            or diag sprintf('died with signal %d', $st & 127);
        is $st >> 8, 0, 'corrupt child index: guarded paths stop cleanly, valid subtrees survive'
            or diag sprintf('child exit %d', $st >> 8);
    }
}

# --- F6: add_many across element magic that frees the rows array -------------
our $rows;
our $decoy;
{
    package Evil::FreeRows;
    # Perl passes aliases, so undef'ing the scalar the caller passed undefs
    # ST(1) itself; the decoy allocation then reuses the freed AV's arena
    # slot, so an unpinned AV* reads the decoy instead of the rows.
    use overload '0+' => sub { undef $main::rows; $main::decoy = ['decoy']; 42 },
                 fallback => 1;
}
{
    my ($done, $st) = run_child(sub {
        my $z = Data::SortedSet::Shared->new(undef, 16);
        my $evil = bless [], 'Evil::FreeRows';
        $main::rows = [ [1, $evil], [2, 2.0], [3, 3.0] ];
        my $added = $z->add_many($main::rows);
        # With the AV pinned for the whole loop, rows 2 and 3 (resolved AFTER
        # the magic window) still land; unpinned, the loop reads the decoy (or
        # worse) and silently loses them.
        my $ok = $added == 3 && $z->exists(1) && $z->exists(2) && $z->exists(3);
        POSIX::_exit($ok ? 0 : 7);
    });
    ok $done, 'add_many: returns when element magic frees the rows array';
    SKIP: {
        skip 'child hung and was killed', 2 unless $done;
        ok !($st & 127), 'add_many: no crash when element magic frees the rows array'
            or diag sprintf('died with signal %d', $st & 127);
        is $st >> 8, 0, 'add_many: rows after the magic window are still added'
            or diag sprintf('child exit %d', $st >> 8);
    }
}

done_testing;
