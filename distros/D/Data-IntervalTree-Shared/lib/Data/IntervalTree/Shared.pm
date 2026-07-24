package Data::IntervalTree::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::IntervalTree::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::IntervalTree::Shared - shared-memory interval tree (overlap / stabbing queries)

=head1 SYNOPSIS

    use Data::IntervalTree::Shared;

    # up to 100_000 intervals
    my $it = Data::IntervalTree::Shared->new(undef, 100_000);

    $it->add($start, $end, $booking_id) for @bookings;   # each interval carries an id

    # which intervals contain a point?
    my @at = $it->stab($t);              # e.g. "what's booked at time $t"

    # which intervals overlap a range?
    my @ov = $it->overlaps($lo, $hi);    # e.g. "any booking touching [$lo,$hi]"
    printf "id %d: [%d, %d]\n", $_->{id}, $_->{lo}, $_->{hi} for @ov;

    # share the index across processes via a backing file
    my $shared = Data::IntervalTree::Shared->new("/tmp/bookings.it", 100_000);

=head1 DESCRIPTION

An B<interval tree> in shared memory: a set of integer intervals C<[lo, hi]> that
answers B<overlap> and B<stabbing> queries far faster than scanning every
interval -- "which stored intervals contain point C<p>?" and "which overlap the
range C<[lo, hi]>?". It complements L<Data::SegmentTree::Shared> (range-aggregate
over indexed positions) and L<Data::KDTree::Shared> (multi-dimensional points):
this one indexes a B<set of intervals> for containment/overlap. Classic uses:
scheduling and calendar conflict detection, IP-range to owner lookup, genomic
feature overlap, and "what is active at time C<t>".

Endpoints are B<signed 64-bit integers> (timestamps, IP addresses, genomic
coordinates -- exact, with no floating-point edge cases). Each interval carries a
user-supplied 64-bit B<id> (defaulting to its insertion index), returned with
every match. Internally it is an B<augmented balanced binary search tree> keyed
by the low endpoint, each node caching the maximum high endpoint of its subtree
so a query prunes whole subtrees that end before it.

Intervals are B<appended in O(1)> and the balanced tree is B<bulk-built on the
first query> after any insert, so query recursion is O(log n + k) deep (k =
matches) regardless of insertion order -- no risk of a degenerate, deep tree.
Because the intervals live in a shared mapping, B<several processes build and
query one index>: any process that opens the same backing file, inherits the
anonymous mapping across C<fork>, or reopens a passed memfd sees the same
intervals. A write-preferring futex rwlock with dead-process recovery guards
mutation; once the tree is built, queries take only the read lock. B<Linux-only>.
Requires 64-bit Perl.

The index has a fixed B<capacity>; adding beyond it croaks. Memory is
C<capacity * 40> bytes for the intervals plus a build scratch of C<capacity * 4>
bytes and a fixed header.

=head1 METHODS

=head2 Constructors

    my $it = Data::IntervalTree::Shared->new($path, $capacity, $mode);
    my $it = Data::IntervalTree::Shared->new(undef, $capacity);
    my $it = Data::IntervalTree::Shared->new_memfd($name, $capacity);
    my $it = Data::IntervalTree::Shared->new_from_fd($fd);

C<$capacity> is the maximum number of intervals (1..2^24). C<new> and
C<new_memfd> croak on an out-of-range C<$capacity>. When reopening an existing
file or memfd the stored geometry wins and the caller's argument is ignored. An
optional file B<mode> may be passed as the last argument to C<new> (e.g. C<0660>)
for cross-user sharing; it defaults to C<0600> (owner-only).

=head2 Adding intervals

    my $i = $it->add($lo, $hi);          # id defaults to the insertion index
    my $i = $it->add($lo, $hi, $id);     # attach an explicit 64-bit id
    $it->build;                          # (optional) force a rebuild now

C<add> appends one interval with integer endpoints C<$lo E<lt>= $hi> (croaks
otherwise) and an optional integer C<$id>, returning its insertion index; it
croaks if the tree is full. Intervals are treated as B<closed> (both endpoints
inclusive). C<build> forces the balanced tree to be (re)built immediately; you
rarely need it, since queries build automatically after inserts.

=head2 Queries

    my @at = $it->stab($point);          # intervals containing $point (lo <= p <= hi)
    my @ov = $it->overlaps($lo, $hi);    # intervals overlapping [$lo, $hi]

C<stab> returns every stored interval that B<contains> the point C<$point>.
C<overlaps> returns every stored interval that B<intersects> the closed range
C<[$lo, $hi]> (i.e. C<interval.lo E<lt>= $hi> and C<interval.hi E<gt>= $lo>);
C<$lo E<gt> $hi> croaks. Both return a list of hash references
C<< { id => ..., lo => ..., hi => ... } >>, sorted by C<lo> ascending. A point
stab is exactly C<overlaps($p, $p)>.

=head2 Introspection and lifecycle

    $it->count;         # number of intervals added
    $it->capacity;      # maximum number of intervals
    $it->clear;         # remove all intervals
    $it->stats;         # { count, capacity, dirty, ops, mmap_size }
    $it->path; $it->memfd; $it->sync; $it->unlink;

C<clear> empties the index. C<sync> flushes the mapping to its backing store (a
no-op for anonymous and memfd trees); C<unlink> removes the backing file (also
callable as C<< Class->unlink($path) >>); C<path> returns the backing path
(C<undef> for anonymous, memfd, or fd-reopened trees) and C<memfd> the backing
descriptor.

=head1 SHARING ACROSS PROCESSES

The index lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Any process can add intervals; the first query after an
add rebuilds the shared tree once (under the write lock), and subsequent queries
run concurrently under the read lock.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Adds are short bounded appends and the bulk
build runs entirely under the write lock, so a crash leaves the index consistent
up to the last completed operation (a crash mid-build simply leaves it marked for
rebuild). B<Limitation>: PID reuse is not detected (very unlikely in practice).

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

=head1 SEE ALSO

L<Data::SegmentTree::Shared> (range-aggregate over indexed positions),
L<Data::KDTree::Shared> (multi-dimensional point index), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
