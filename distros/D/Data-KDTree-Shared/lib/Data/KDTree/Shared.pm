package Data::KDTree::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::KDTree::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::KDTree::Shared - shared-memory k-d tree (nearest-neighbour + range search)

=head1 SYNOPSIS

    use Data::KDTree::Shared;

    # up to 100_000 points in 2 dimensions
    my $kd = Data::KDTree::Shared->new(undef, 2, 100_000);

    $kd->add([$lon, $lat], $city_id) for @cities;   # each point carries an id

    my $near = $kd->nearest([$x, $y]);          # { id => ..., dist => ... }
    my @k5   = $kd->knn([$x, $y], 5);           # 5 nearest, closest first
    my @box  = $kd->range([$x0, $y0], [$x1, $y1]); # ids inside a bounding box
    my @ball = $kd->radius([$x, $y], 3.0);      # points within distance 3

    # share the index across processes via a backing file
    my $shared = Data::KDTree::Shared->new("/tmp/points.kd", 2, 100_000);

=head1 DESCRIPTION

A B<k-d tree> in shared memory: a spatial index over points in up to 16
dimensions that answers B<nearest-neighbour>, B<k-nearest>, B<bounding-box>, and
B<radius> queries far faster than scanning every point. It complements
L<Data::SpatialHash::Shared> (a uniform grid, ideal for fixed-radius proximity):
a k-d tree adapts to the point density and answers exact k-NN and arbitrary-box
queries.

Points are B<appended in O(1)> and each carries a user-supplied 64-bit B<id>
(defaulting to its insertion index). To keep queries fast regardless of insertion
order, the tree is B<bulk-built balanced> (median split on a cycling axis) the
first time it is queried after any insert, so query recursion is O(log n) deep --
there is no risk of a degenerate, deep tree from sorted inserts.

Because the points live in a shared mapping, B<several processes build and query
one index>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd sees the same points. A
write-preferring futex rwlock with dead-process recovery guards mutation; once
the tree is built, queries take only the read lock, so many run concurrently.
Coordinates are C<double>; a non-finite coordinate croaks. B<Linux-only>.
Requires 64-bit Perl.

The index has a fixed B<capacity>; adding beyond it croaks. Memory is
C<capacity * (dims * 8 + 16)> bytes for the points plus a build scratch of
C<capacity * 4> bytes and a fixed header.

=head1 METHODS

=head2 Constructors

    my $kd = Data::KDTree::Shared->new($path, $dims, $capacity, $mode);
    my $kd = Data::KDTree::Shared->new(undef, $dims, $capacity);
    my $kd = Data::KDTree::Shared->new_memfd($name, $dims, $capacity);
    my $kd = Data::KDTree::Shared->new_from_fd($fd);

C<$dims> is the number of dimensions (1..16) and C<$capacity> the maximum number
of points (1..2^24). C<new> and C<new_memfd> croak on an out-of-range C<$dims> or
C<$capacity>. When reopening an existing file or memfd the stored geometry wins
and the caller's arguments are ignored. An optional file B<mode> may be passed as
the last argument to C<new> (e.g. C<0660>) for cross-user sharing; it defaults to
C<0600> (owner-only).

=head2 Adding points

    my $i = $kd->add(\@coords);          # id defaults to the insertion index
    my $i = $kd->add(\@coords, $id);     # attach an explicit 64-bit id
    $kd->build;                          # (optional) force a rebuild now

C<add> appends one point (an array reference of exactly C<$dims> finite
coordinates) with an optional integer C<$id> and returns its insertion index; it
croaks if the tree is full or a coordinate is missing or non-finite. C<build>
forces the balanced tree to be (re)built immediately; you rarely need it, since
queries build automatically after inserts.

=head2 Queries

    my $near  = $kd->nearest(\@point);       # { id, dist } or undef if empty
    my @knn   = $kd->knn(\@point, $m);       # up to $m nearest, closest first
    my @ids   = $kd->range(\@lo, \@hi);      # ids whose coords lie in [lo, hi] per axis
    my @ball  = $kd->radius(\@point, $r);    # { id, dist } within Euclidean distance $r

C<nearest> returns the single closest point as C<< { id => ..., dist => ... } >>
(Euclidean distance), or C<undef> if the index is empty. C<knn> returns up to
C<$m> such hash references sorted by increasing distance. C<range> returns a plain
list of the ids of every point inside the axis-aligned box with corners C<\@lo>
and C<\@hi> (order unspecified). C<radius> returns C<< { id, dist } >> hash
references for every point within Euclidean distance C<$r>, closest first. All
query points and box corners are array references of exactly C<$dims> finite
coordinates.

=head2 Introspection and lifecycle

    $kd->count;         # number of points added
    $kd->capacity;      # maximum number of points
    $kd->dims;          # number of dimensions
    $kd->clear;         # remove all points
    $kd->stats;         # { count, dims, capacity, dirty, ops, mmap_size }
    $kd->path; $kd->memfd; $kd->sync; $kd->unlink;

C<clear> empties the index. C<sync> flushes the mapping to its backing store (a
no-op for anonymous and memfd trees); C<unlink> removes the backing file (also
callable as C<< Class->unlink($path) >>); C<path> returns the backing path
(C<undef> for anonymous, memfd, or fd-reopened trees) and C<memfd> the backing
descriptor.

=head1 SHARING ACROSS PROCESSES

The index lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Any process can add points; the first query after an add
rebuilds the shared tree once (under the write lock), and subsequent queries run
concurrently under the read lock.

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

L<Data::SpatialHash::Shared> (uniform-grid proximity), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
