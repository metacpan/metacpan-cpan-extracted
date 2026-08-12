package Data::Fenwick::Shared;
use strict;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Data::Fenwick::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::Fenwick::Shared - shared-memory Fenwick tree (binary indexed tree; point
or range update) for Linux

=head1 SYNOPSIS

    use Data::Fenwick::Shared;

    # a tree over positions 1..1_000_000, anonymous mapping
    my $fen = Data::Fenwick::Shared->new(undef, 1_000_000);

    $fen->update(5, 3);        # add 3 at position 5
    $fen->update(9, 7);        # add 7 at position 9

    $fen->prefix(9);           # 10  (sum of positions 1..9)
    $fen->range(5, 9);         # 10  (sum of positions 5..9)
    $fen->point(5);            # 3   (value at position 5)
    $fen->total;               # 10  (sum of all positions)

    $fen->set(5, 100);         # set position 5 to 100 (returns the old value)

    # rank / weighted lookup: smallest position whose prefix sum reaches a target
    $fen->find(50);            # first position i with prefix(i) >= 50

    # share across processes via a backing file
    my $shared = Data::Fenwick::Shared->new("/tmp/counts.fen", 1_000_000);

    # range-update mode: add to a whole range in O(log n), then query ranges
    my $rng = Data::Fenwick::Shared->new_range(undef, 1_000_000);
    $rng->range_add(10, 20, 5);   # add 5 to every position in [10, 20]
    $rng->range(10, 20);          # 55  (sum over the range)

    # freeze and ship: query it read-only (lock-free) on other machines
    $shared->freeze;
    my $ro = Data::Fenwick::Shared->new_readonly("/tmp/counts.fen");
    $ro->prefix(500_000);

=head1 DESCRIPTION

A B<Fenwick tree> (binary indexed tree) in shared memory: a fixed-size array of
C<n> signed 64-bit integer positions that supports B<point update> and
B<prefix-sum query> in C<O(log n)> each, plus an C<O(log n)> binary search for
the position at which a running total is reached. It is the compact,
update-friendly structure behind cumulative-frequency tables, running rank/order
statistics, and weighted random sampling.

Positions are numbered B<1 to n> (1-indexed). C<update($i, $delta)> adds a
(possibly negative) delta at position C<$i>; C<prefix($i)> returns the sum of
positions C<1..$i>; C<range($l, $r)> the sum of C<$l..$r>; C<point($i)> the
current value at a single position; and C<total> the sum of everything. C<set>
overwrites a position with an absolute value. C<find($target)> returns the
smallest position whose prefix sum is at least C<$target> (meaningful when all
stored values are non-negative) -- the operation that turns a Fenwick tree into a
weighted sampler or a rank index.

The tree lives in a shared mapping, so B<several processes update and query one
structure>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd sees the others' updates and
contributes its own. A write-preferring futex rwlock with dead-process recovery
guards mutation, so many processes may C<update> and query concurrently. Two
trees of equal size C<n> can be C<merge>d by element-wise addition (a Fenwick
tree is linear, so the merge of C<tree(A)> and C<tree(B)> is C<tree(A+B)>).

Values are signed 64-bit integers; sums that overflow 64 bits wrap, as with any
native integer arithmetic. Memory is C<(n+1) * 8> bytes for the tree plus a
fixed header. B<Linux-only>. Requires 64-bit Perl.

=head2 Range-update mode

A tree created with C<new_range> supports B<range update> as well as range query:
C<range_add($l, $r, $delta)> adds a delta to every position in C<[$l, $r]> in
C<O(log n)>, and C<prefix>/C<range>/C<point>/C<total> report the resulting sums.
It uses the classic B<two-BIT> technique (a second binary indexed tree tracking
the weighted difference), so a range-mode tree costs B<twice the memory>
(C<2 * (n+1) * 8> bytes) but adds O(log n) range updates a plain Fenwick tree
cannot do. C<update($i, $delta)> and C<set> still work (a point update is just
C<range_add($i, $i, $delta)>). C<find> and C<merge> are B<not> available in range
mode (the two-BIT layout has no single-BIT binary lift); use a point tree for
those. The mode is recorded in the header, so a reopened segment stays range mode.
Note that the 0.02 on-disk format is incompatible with 0.01: a file created by
0.01 cannot be opened and must be recreated.

=head1 METHODS

=head2 Constructors

    my $fen = Data::Fenwick::Shared->new($path, $n);
    my $fen = Data::Fenwick::Shared->new(undef, $n);            # anonymous
    my $fen = Data::Fenwick::Shared->new_memfd($name, $n);
    my $fen = Data::Fenwick::Shared->new_from_fd($fd);
    my $ro  = Data::Fenwick::Shared->new_readonly($path);       # frozen file, read-only

    # range-update mode (two BITs) -- same arguments
    my $fen = Data::Fenwick::Shared->new_range($path, $n);
    my $fen = Data::Fenwick::Shared->new_range_memfd($name, $n);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$n> is the number of positions (at least 1); positions are then addressed as
C<1..$n>. C<new> and C<new_memfd> croak if C<$n> is less than 1 or exceeds the
tree cap. When reopening an existing file or memfd, the stored C<n> wins and
the caller's C<$n> argument is ignored -- but a positive C<$n> placeholder is
still required, since the constructor validates C<$n> before the stored value
wins. C<new_memfd> creates a Linux memfd (transferable via its C<memfd>
descriptor); C<new_from_fd> reopens one in another process. The descriptor you
pass is duplicated (C<F_DUPFD_CLOEXEC>), so it stays yours to close and
closing it does not disturb the handle. C<new_readonly> opens a B<frozen> file
read-only for lock-free querying (see L</"FROZEN (READ-ONLY) MODE">). An
optional file B<mode> may be passed as the last argument to C<new> (e.g.
C<0660>) to opt a newly-created backing file into cross-user sharing; it
defaults to C<0600> (owner-only).

=head2 Updating

    $fen->update($i, $delta);        # add $delta at position $i (1 <= $i <= n)
    $fen->range_add($l, $r, $delta);  # add $delta to every position in [$l, $r] (range mode)
    my $old = $fen->set($i, $value);  # set position $i to $value; returns the old value
    $fen->clear;                      # reset every position to 0

C<range_add> adds a delta to a whole inclusive range in C<O(log n)> and requires
a B<range-mode> tree (C<new_range>); it croaks on a point-mode tree. C<update>
adds a signed delta at a single position and returns nothing. C<set>
overwrites a position with an absolute value and returns its previous value (it
is C<update($i, $value - point($i))> done atomically under one lock). Both croak
if C<$i> is outside C<1..n>. C<clear> zeroes the whole tree.

=head2 Querying

    my $s = $fen->prefix($i);       # sum of positions 1..$i (0 <= $i <= n; prefix(0) == 0)
    my $s = $fen->range($l, $r);    # sum of positions $l..$r (1 <= $l <= $r <= n)
    my $v = $fen->point($i);        # value at position $i
    my $t = $fen->total;            # sum of all positions (== prefix(n))
    my $i = $fen->find($target);    # smallest position with prefix >= $target

C<prefix>, C<range>, C<point>, and C<total> are C<O(log n)> reads returning
signed integers. C<find> binary-searches the tree for the smallest position
whose prefix sum is at least C<$target>, returning that position or C<n+1> if no
prefix reaches it. C<find> is only meaningful when every stored value is
non-negative (a cumulative distribution): it is the core of weighted sampling
(draw C<$target> uniformly in C<[1, total]> and C<find> the bucket) and of
order-statistic / rank queries. Out-of-range positions croak. C<find> requires a
B<point-mode> tree (it croaks in range mode).

=head2 Merging, introspection, lifecycle

    $fen->merge($other);            # element-wise add (point mode; both must have equal n)
    $fen->size;                     # n, the number of positions
    $fen->is_range;                 # true for a range-mode (two-BIT) tree
    $fen->stats;                    # { size, total, ops, mmap_size, range }
    $fen->path; $fen->memfd; $fen->sync; $fen->unlink;

C<merge> adds another tree's contents into this one position by position; both
trees must have the same C<n> or it croaks, and both must be B<point-mode>
(C<merge> croaks in range mode). The other tree is snapshotted under its own
read lock, so two processes may merge concurrently without deadlock.
C<is_range> reports whether the tree is range mode. C<size> (also C<capacity>)
is C<n>. C<sync> flushes the mapping to its backing store (a no-op for
anonymous and memfd trees); C<unlink> removes the backing file (also callable
as C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef>
for anonymous, memfd, or fd-reopened trees) and C<memfd> the backing
descriptor -- the memfd of a C<new_memfd> tree or the dup'd fd of a
C<new_from_fd> tree, and -1 for file-backed or anonymous trees.

=head1 STATS

C<stats()> returns a hashref: C<size> (the number of positions C<n>), C<total>
(the current sum of all positions), C<ops> (running count of write-path calls --
C<update>, C<range_add>, C<set>, C<merge>, C<clear>), C<mmap_size> (bytes of the
shared mapping), C<range> (1 for a range-mode tree, 0 for a point-mode tree),
C<frozen> (1 if the tree has been sealed by C<freeze> and is immutable, else 0),
and C<readonly> (1 if this handle is a read-only view -- from C<new_readonly>,
or the handle that called C<freeze> -- else 0).

=head1 SHARING ACROSS PROCESSES

The tree lives in a shared mapping, shared the same three ways as the rest of the
family: a B<backing file> (every process calls C<< new($path, $n) >> on the same
path with a matching C<$n>), an B<anonymous mapping inherited across C<fork>>, or
a B<memfd> whose descriptor is passed to an unrelated process (over a UNIX socket
via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process updates
and queries the same tree>.

    # producer and consumer share one running-sum tree with no coordination
    my $fen = Data::Fenwick::Shared->new(undef, 1000);   # before fork
    unless (fork) { $fen->update($_, 1) for 1 .. 500; exit }
    wait;
    print $fen->total, "\n";   # 500 -- the child's updates

=head1 FROZEN (READ-ONLY) MODE

A file-backed tree can be B<frozen> and then shipped to other machines, where
consumers open it B<read-only> and query it with B<no locking at all>.

    # producer: build, freeze, ship the file
    my $fen = Data::Fenwick::Shared->new("/tmp/counts.fen", 1_000_000);
    $fen->update($_, $counts{$_}) for keys %counts;
    $fen->freeze;                 # seal: now immutable, and $fen itself is read-only
    # ... copy /tmp/counts.fen to another host ...

    # consumer (any process, same architecture): read-only, lock-free
    my $ro = Data::Fenwick::Shared->new_readonly("/tmp/counts.fen");
    $ro->prefix($_) for @queries;

C<freeze> takes the write lock, marks the tree B<permanently immutable> (there
is no unfreeze -- rebuild the file to change it), and flushes the seal to disk.
A frozen tree rejects every mutator (C<update>, C<range_add>, C<set>, C<clear>,
C<merge>) with a croak, and a read-write reopen (C<< new($path, ...) >> or
C<new_from_fd>) of a sealed file is B<refused> -- so a shipped artifact can
never be silently mutated out from under its readers.

C<new_readonly($path)> maps the file C<O_RDONLY> / C<PROT_READ> and B<requires
it to be frozen> (it croaks on a file that was never C<freeze>d). Because a
sealed tree's values and geometry are immutable, C<prefix>, C<range>, C<point>,
C<total>, C<find>, and C<stats> read them B<directly, taking no reader lock> --
the mapping is never written, so a read-only view works from a read-only file
descriptor or a read-only filesystem, and any number of processes can share one
C<PROT_READ> mapping. C<frozen> and C<readonly> report the two states. A
B<range-mode> tree (C<new_range>) can be frozen and reopened read-only the same
way as a point-mode one; C<find> and C<merge> stay unavailable in range mode
regardless of the frozen state.

B<Portability.> The on-disk format is native binary (native-endian 64-bit
words), so a frozen file may be copied only between machines of the B<same
architecture>; a wrong-endian file is rejected at open by the magic check.
B<Copy the file to each consumer> -- do not share one file over a network
filesystem: the lock is a Linux futex (process-local to one kernel), and the
"no live writer" contract assumes a static copy. Linux-only; 64-bit Perl.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default. To share
a backing file across users, pass an explicit octal file mode such as C<0660>
as the last argument to C<new>; the mode is applied when the file is created,
and when a file left behind by an interrupted create is re-initialized (see
L</CRASH SAFETY>); a file already in use keeps its own permissions. The file
is opened with C<O_NOFOLLOW> (a symlink at the path is refused) and C<O_EXCL>;
the on-disk header is validated when the file is attached. Any process you
grant write access to a shared mapping is trusted not to corrupt it while
others are using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Each C<update> is a short O(log n) sequence of int64 stores, so a crash
leaves the tree consistent up to the last completed operation. B<Limitation>: PID
reuse is not detected (very unlikely in practice).

Reader-slot exhaustion (slotless readers): dead-process recovery attributes a
crashed lock holder's contribution through its reader-slot. The slot table holds
1024 entries (one per concurrent reader process). If more than that many reader
processes share one mapping at once, a reader that cannot claim a slot proceeds
"slotless" -- it still takes the read lock but leaves no per-process record. If
such a slotless reader is then killed while holding the read lock, its share of
the lock cannot be attributed to a dead process, so writer recovery cannot
reclaim it and writers may block until the mapping is recreated. Reaching this
needs more than 1024 concurrent reader processes on one mapping plus a crash in
the brief read-lock window; the dead-process slot reclaim keeps the table from
filling with stale entries, so in practice it is very unlikely.

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete Fenwick tree file
left by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 SEE ALSO

L<Data::SortedSet::Shared> (order-statistics ZSET), L<Data::NDArray::Shared>
(dense numeric arrays), L<Data::Histogram::Shared> (HdrHistogram), and the rest
of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
