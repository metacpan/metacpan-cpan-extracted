package Data::Fenwick2D::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::Fenwick2D::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::Fenwick2D::Shared - shared-memory 2-D Fenwick tree (binary indexed tree) for Linux

=head1 SYNOPSIS

    use Data::Fenwick2D::Shared;

    # a rows x cols grid of signed 64-bit integers, all 0
    my $grid = Data::Fenwick2D::Shared->new(undef, 24, 7);

    $grid->update(9, 1, 12);       # add 12 at cell (row 9, col 1)
    $grid->update(22, 5, 30);      # add 30 at cell (22, 5)

    $grid->point(22, 5);           # 30  (value at a single cell)
    $grid->prefix(12, 5);          # sum over the rectangle [1..12] x [1..5]
    $grid->rect(8, 1, 12, 5);      # sum over [8..12] x [1..5]
    $grid->total;                  # sum over the whole grid

    $grid->set(9, 1, 100);         # set cell (9,1) to 100 (returns the old value)

    # share the grid across processes via a backing file
    my $shared = Data::Fenwick2D::Shared->new("/tmp/heatmap.f2d", 24, 7);

    # freeze and ship: query it read-only (lock-free) on other machines
    $shared->freeze;
    my $ro = Data::Fenwick2D::Shared->new_readonly("/tmp/heatmap.f2d");
    $ro->point(22, 5);

=head1 DESCRIPTION

A B<2-D Fenwick tree> (binary indexed tree) in shared memory: a fixed
C<rows> x C<cols> grid of signed 64-bit integers that supports B<point update>
and B<rectangle-sum query> in C<O(log rows * log cols)> each. It is the compact,
update-friendly structure behind 2-D cumulative-frequency tables, running
heatmaps, and image / grid area-sum queries -- the two-dimensional companion to
L<Data::Fenwick::Shared>.

Cells are addressed by a B<1-based> C<(row, col)> pair, C<1..rows> by C<1..cols>.
C<update($x, $y, $delta)> adds a (possibly negative) delta at a cell;
C<prefix($x, $y)> returns the sum of the rectangle from the origin,
C<[1..$x] x [1..$y]>; C<rect($x1, $y1, $x2, $y2)> the sum of any axis-aligned
rectangle (via inclusion-exclusion of four prefix queries); C<point($x, $y)> a
single cell's value; and C<total> the sum of the whole grid. C<set> overwrites a
cell with an absolute value.

The grid lives in a shared mapping, so B<several processes update and query one
grid>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd sees the others' updates and
contributes its own. A write-preferring futex rwlock with dead-process recovery
guards mutation, so many processes may C<update> and query concurrently; queries
take only the read lock.

Values and rectangle sums are signed 64-bit integers; sums that overflow 64 bits
wrap, as with any native integer accumulator. Memory is
C<(rows+1) * (cols+1) * 8> bytes for the grid plus a fixed header. B<Linux-only>.
Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $grid = Data::Fenwick2D::Shared->new($path, $rows, $cols);
    my $grid = Data::Fenwick2D::Shared->new(undef, $rows, $cols);      # anonymous
    my $grid = Data::Fenwick2D::Shared->new_memfd($name, $rows, $cols);
    my $grid = Data::Fenwick2D::Shared->new_from_fd($fd);
    my $ro   = Data::Fenwick2D::Shared->new_readonly($path);           # frozen file, read-only

C<$rows> and C<$cols> are the grid dimensions (each at least 1, up to 2^24); cells
are then addressed as C<(1..$rows, 1..$cols)>. Every cell starts at 0. C<new> and
C<new_memfd> croak if a dimension is below 1 or above the cap. When reopening an
existing file or memfd the stored dimensions win and the caller's arguments are
ignored. An optional file B<mode> may be passed as the last argument to C<new>
(e.g. C<0660>) to opt a newly-created backing file into cross-user sharing; it
defaults to C<0600> (owner-only). C<new_readonly> opens a B<frozen> file
read-only for lock-free querying (see L</"FROZEN (READ-ONLY) MODE">).

=head2 Updating

    $grid->update($x, $y, $delta);       # add $delta at cell ($x, $y)
    my $old = $grid->set($x, $y, $value); # set cell ($x, $y) to $value; returns the old value
    $grid->clear;                         # reset every cell to 0

C<update> adds a signed delta at a single cell. C<set> overwrites a cell with an
absolute value and returns its previous value (it is
C<update($x, $y, $value - point($x, $y))> done atomically under one lock). Both
croak if C<($x, $y)> is outside C<(1..rows, 1..cols)>. C<clear> zeroes the grid.

=head2 Querying

    my $v = $grid->point($x, $y);            # value at a single cell
    my $s = $grid->prefix($x, $y);           # sum over [1..$x] x [1..$y] (origin rectangle)
    my $s = $grid->rect($x1, $y1, $x2, $y2);  # sum over [$x1..$x2] x [$y1..$y2]
    my $t = $grid->total;                    # sum over the whole grid

C<prefix> returns the cumulative sum of the rectangle anchored at the origin;
either coordinate may be 0 (an empty rectangle, sum 0). C<rect> returns the sum of
any inclusive axis-aligned rectangle, computed from four prefix queries by
inclusion-exclusion; it croaks unless C<< 1 <= $x1 <= $x2 <= rows >> and
C<< 1 <= $y1 <= $y2 <= cols >>. C<point> is the C<1x1> rectangle at a cell.
C<total> is C<prefix(rows, cols)>. Every query takes only the read lock, so many
run concurrently.

=head2 Introspection and lifecycle

    $grid->rows; $grid->cols;    # the grid dimensions
    $grid->stats;                # { rows, cols, total, ops, mmap_size, frozen, readonly }
    $grid->path; $grid->memfd; $grid->sync; $grid->unlink;

C<stats> returns a hash reference with the dimensions, the current grand total,
the running count of write-path operations, the mapping size, whether the grid
has been sealed by C<freeze> (C<frozen>), and whether this handle is a
read-only view (C<readonly>; see L</"FROZEN (READ-ONLY) MODE">). C<sync> flushes
the mapping to its backing store (a no-op for anonymous and memfd grids, and for
a read-only handle); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened grids) and C<memfd> the backing descriptor.

=head1 SHARING ACROSS PROCESSES

The grid lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> passed to an unrelated process and reopened with C<<
new_from_fd($fd) >>. The descriptor you pass is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the handle. Every process's updates land in the one shared grid, and
queries take only the read lock so many readers proceed concurrently.

=head1 FROZEN (READ-ONLY) MODE

A file-backed grid can be B<frozen> and then shipped to other machines, where
consumers open it B<read-only> and query it with B<no locking at all>.

    # producer: build, freeze, ship the file
    my $grid = Data::Fenwick2D::Shared->new("/tmp/heatmap.f2d", 24, 7);
    $grid->update(9, 1, 12);
    $grid->freeze;                 # seal: now immutable, and $grid itself is read-only
    # ... copy /tmp/heatmap.f2d to another host ...

    # consumer (any process, same architecture): read-only, lock-free
    my $ro = Data::Fenwick2D::Shared->new_readonly("/tmp/heatmap.f2d");
    $ro->rect(8, 1, 12, 5);

C<freeze> takes the write lock, marks the grid B<permanently immutable> (there
is no unfreeze -- rebuild the file to change it), and flushes the seal to disk.
A frozen grid rejects every mutator (C<update>, C<set>, C<clear>) with a croak,
and a read-write reopen (C<< new($path, ...) >> or C<new_from_fd>) of a sealed
file is B<refused> -- so a shipped artifact can never be silently mutated out
from under its readers.

C<new_readonly($path)> maps the file C<O_RDONLY> / C<PROT_READ> and B<requires
it to be frozen> (it croaks on a file that was never C<freeze>d). Because a
sealed grid's cells and geometry are immutable, C<prefix>, C<rect>, C<point>,
C<total>, and C<stats> read them B<directly, taking no reader lock> -- the
mapping is never written, so a read-only view works from a read-only file
descriptor or a read-only filesystem, and any number of processes can share one
C<PROT_READ> mapping. C<frozen> and C<readonly> report the two states.

B<Portability.> The on-disk format is native binary (native-endian 64-bit
words), so a frozen file may be copied only between machines of the B<same
architecture>; a wrong-endian file is rejected at open by the magic check.
B<Copy the file to each consumer> -- do not share one file over a network
filesystem: the lock is a Linux futex (process-local to one kernel), and the
"no live writer" contract assumes a static copy. Linux-only; 64-bit Perl.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Each update is a short bounded
C<O(log rows * log cols)> walk, so a crash leaves the grid consistent up to the
last completed operation. B<Limitation>: PID reuse is not detected (very unlikely
in practice).

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
apart from a corrupt one and C<new> croaks with C<incomplete Fenwick2D tree
file left by an interrupted create; remove it and retry>. Such a file never
held any data, so removing it is safe.

=head1 SEE ALSO

L<Data::Fenwick::Shared> (the 1-D Fenwick tree: prefix sums, point/range update,
weighted lookup), and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
