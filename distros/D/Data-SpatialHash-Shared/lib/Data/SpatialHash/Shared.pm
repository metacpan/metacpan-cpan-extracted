package Data::SpatialHash::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::SpatialHash::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::SpatialHash::Shared - Shared-memory spatial hash index for Linux

=head1 SYNOPSIS

    use Data::SpatialHash::Shared;

    # 100k-entry map, auto-sized buckets, 1.0 world-unit cells
    my $s = Data::SpatialHash::Shared->new(undef, 100_000, 0, 1.0);

    my $h = $s->insert(10.5, 20.5, 42);      # 2D point id=42 -> handle
    $s->move($h, 11.0, 21.0);                # entity moved
    my @near = $s->query_radius(10, 20, 5);  # ids within radius 5
    my @nn   = $s->query_knn(10, 20, 3);     # 3 nearest ids

    my $p = $s->insert(1, 2, 3, 7);          # 3D point id=7
    $s->each_in_radius(0, 0, 0, 10, sub { my ($id) = @_; });

    $s->remove($h);
    my $stats = $s->stats;                   # { count => ..., max_chain => ... }

    # toroidal world + a one-call collision broad-phase (e.g. a game tick)
    my $w = Data::SpatialHash::Shared->new(undef, 100_000, 0, 16, wrap => [2000, 2000]);
    my $a = $w->insert(5, 5, 1);  $w->set_radius($a, 3);   # actor 1, interaction radius 3
    $w->move_many([ [$a, 6, 6] ]);                          # bulk-reposition each tick
    my $near = $w->query_radius_many([ [6, 6, 3] ]);        # batched neighbor queries, one lock
    $w->each_colliding_pair(sub { my ($x, $y) = @_; });     # every colliding pair, seam-aware

    # spherical world (planet): geo proximity + cube-sphere chunk/LOD ids
    my $g = Data::SpatialHash::Shared->new(undef, 100_000, 0, 1000, sphere => 6_371_000);
    my $e = $g->insert_geo(0.81, 0.21, 500, 1);             # lat/lon radians, 500 m altitude
    my @hit = $g->query_geo_radius(0.81, 0.21, 500, 2000);  # within 2 km (true 3D distance)
    my $chunk = $g->cube_cell_geo(0.81, 0.21, 12);          # level-12 cube-sphere cell id

=head1 DESCRIPTION

Sparse spatial hash in shared memory: an unbounded Euclidean grid by default, or
a bounded seamless torus (see L</Toroidal space>).  Positions and values are
stored in a flat array of entries; a hash table of buckets maps cell coordinates
to entry chains.  Coordinates are arbitrary floats in 2D or 3D; for 2D use,
simply omit the C<z> argument (it defaults to 0).  For planets and other
spherical worlds, geo helpers map latitude/longitude/altitude to 3D and a
cube-sphere cell scheme provides chunk and level-of-detail ids
(see L</Spherical worlds>).

Multiple processes can map the same hash and read and write it
concurrently; access is serialized by a write-preferring futex rwlock that
recovers automatically if a lock holder dies (see L</CRASH SAFETY>).

B<Linux-only>.  Requires 64-bit Perl.

=head2 Coordinate model

Space is divided into axis-aligned cells of size C<cell_size>.  A point
at (x, y, z) lands in cell (floor(x/cell_size), floor(y/cell_size),
floor(z/cell_size)).  Spatial queries walk all cells that overlap the
query region; smaller cells reduce false positives at the cost of
more bucket lookups.

=head2 2D vs 3D

All methods that accept coordinates accept either (x, y) or (x, y, z).
When z is omitted it is treated as 0.  A handle created with a 2D
insert can be queried with either 2D or 3D calls.

=head2 Toroidal space

By default the grid is unbounded and Euclidean.  Construct with
C<< wrap => [$Wx, $Wy] >> (2D) or C<< [$Wx, $Wy, $Wz] >> (3D) to make space a
seamless B<torus>: neighbour-cell expansion wraps around the grid edges and
C<query_radius>, C<query_knn>, C<each_in_radius>, C<query_radius_many>, and the
pair emitters all use the minimum-image (shortest wrapping) distance

    dx = abs(ax - bx);  dx = $Wx - dx if dx > $Wx / 2;   # per axis

so an entry near C<0> and one near C<$Wx> are neighbours.  Keep positions within
C<[0, $W)> per axis for the metric to be meaningful.  Each wrapped extent must be
a positive multiple of C<cell_size> so the cells tile the world exactly,
otherwise the constructor croaks.  C<query_cell> resolves its coordinate to a
wrapped cell, but C<query_aabb> uses the literal (non-wrapping) box even in a
wrapping world.  The wrap configuration is part of the mapped format and is
restored on reopen; the C<world> accessor returns the extents.

=head1 METHODS

=head2 Constructors

    my $s = Data::SpatialHash::Shared->new($path, $max, $buckets, $cell);
    my $s = Data::SpatialHash::Shared->new(undef, $max, $buckets, $cell);
    my $s = Data::SpatialHash::Shared->new_memfd($name, $max, $buckets, $cell);
    my $s = Data::SpatialHash::Shared->new_from_fd($fd);
    my $s = Data::SpatialHash::Shared->new($path, $max, $buckets, $cell, wrap => [$Wx, $Wy]);

C<$path> is the backing file path; C<undef> creates an anonymous mapping.
C<$max> is the maximum number of entries.  C<$buckets> is the bucket count
(0 = auto).  C<$cell> is the cell size (float).

Pass C<< wrap => [$Wx, $Wy] >> (or C<< [$Wx, $Wy, $Wz] >>) to make the world a
seamless torus of those extents (see L</Toroidal space>); omit it for an
unbounded Euclidean space.

When reopening an existing backing file or memfd, the stored header wins: the
caller's C<$max>, C<$buckets>, C<$cell>, C<wrap>, and C<sphere> arguments are
ignored and the file's original values are used.

C<new_memfd> creates a Linux memfd (anonymous but transferable via C<memfd>
file descriptor).  C<new_from_fd> reopens an existing memfd in another
process.

=head2 Mutators

    my $h = $s->insert(x, y, value);        # 2D insert -- returns handle or undef
    my $h = $s->insert(x, y, z, value);     # 3D insert
    my $h = $s->insert(x, y, z, value, r);  # 3D insert with an interaction radius
    $s->set_radius($h, $r);                 # set/replace an entry's radius
    $s->move($h, x, y);                     # relocate entry (2D)
    $s->move($h, x, y, z);                  # relocate entry (3D)
    $s->remove($h);                         # free entry slot
    $s->set_value($h, $v);                  # update stored value
    $s->clear;                              # remove all entries
    my @ids = $s->insert_many([ [x,y,value], [x,y,value,r], ... ]);  # bulk insert
    my $n   = $s->move_many([ [handle,x,y], [handle,x,y,z], ... ]);  # bulk move

C<insert> returns a handle (opaque integer) on success, or C<undef> if
C<max_entries> is exhausted.  C<move> and C<remove> return true on success,
or false if the handle is invalid or already removed.  C<set_value> instead
croaks on an invalid or freed handle; it and C<clear> return nothing.

Each entry may carry an B<interaction radius> (default 0; must be finite and
non-negative), used by C<each_colliding_pair>.  Set it with the 5-argument C<insert> or with
C<set_radius> (which croaks on an invalid or freed handle); for a 2D entry with
a radius, insert then call C<set_radius>.  C<insert_many> and C<move_many> apply
a whole batch under a single lock acquisition -- each row is an arrayref.
C<insert_many> inserts B<2D> entries (rows C<[x,y,value]> or
C<[x,y,value,radius]>; use C<insert> in a loop for 3D) and returns the list of
handles, with C<undef> for any row that overflowed the pool, was malformed
(not an arrayref of length 3 or 4), or carried a negative or non-finite radius.  C<move_many> takes C<[handle,x,y]> or
C<[handle,x,y,z]> rows and returns the count successfully moved; freed/invalid
handles and malformed rows are skipped.

Handles are entry slot indices starting at B<0>, and B<0 is false in
Perl>.  The very first insert into a fresh hash returns handle C<0>.
Always test the result with C<defined $h>, never for truthiness:

    my $h = $s->insert($x, $y, $v);
    die "full" unless defined $h;   # correct: handle 0 is valid
    # WRONG: "unless $h" would treat the first handle (0) as failure

=head2 Accessors

    $s->has($h);              # true if handle is live
    $s->value($h);            # stored value
    $s->get_radius($h);       # stored interaction radius (0 if unset)
    my ($x, $y, $z) = $s->position($h);   # current position

C<has> is the safe predicate for a possibly-freed handle; C<value>,
C<position>, and C<get_radius> croak on an invalid or freed handle.

=head2 Queries

Most query methods return a list of stored values (not handles) for
matching entries; C<query_radius_many> instead returns an arrayref of id-list
arrayrefs (see L</Batched radius queries>).  For C<query_knn>, results are in
nearest-first order.

    my @ids = $s->query_radius(x, y, r);         # 2D radius search
    my @ids = $s->query_radius(x, y, z, r);      # 3D radius search
    my @ids = $s->query_aabb(x0, y0, x1, y1);    # 2D axis-aligned box
    my @ids = $s->query_aabb(x0, y0, z0, x1, y1, z1);  # 3D box
    my @ids = $s->query_cell(x, y);              # single cell (2D)
    my @ids = $s->query_cell(x, y, z);           # single cell (3D)
    my @ids = $s->query_knn(x, y, k);            # k nearest (2D)
    my @ids = $s->query_knn(x, y, z, k);         # k nearest (3D)
    $s->each_in_radius(x, y, r, sub { my ($v) = @_; ... });    # 2D cb
    $s->each_in_radius(x, y, z, r, sub { my ($v) = @_; ... }); # 3D cb
    my $lists = $s->query_radius_many([ [x,y,r], [x,y,z,r] ]); # N radius queries, one lock

C<query_radius> and C<each_in_radius> require a finite, non-negative radius, and
C<query_knn> requires C<k> to be at least 1; out-of-range values croak.  The
radius is B<inclusive> (a point at exactly the radius matches), unlike the strict
C<each_pair_within>; C<query_geo_radius> is inclusive too, as are C<query_aabb>'s
box edges.

C<each_in_radius> snapshots the matching values under the read lock, then
invokes the callback once per value after the lock is released.  Because the
lock is dropped before any callback runs, the callback may safely call back
into the same map (for example C<has> or C<move>) without deadlock.

=head3 Batched radius queries

    my $lists = $s->query_radius_many([ [x, y, r], [x, y, z, r], ... ]);
    # $lists->[i] is an arrayref of ids, == [ $s->query_radius(@{ $queries->[i] }) ]

C<query_radius_many> runs a whole batch of radius queries under a B<single> read
lock and returns an arrayref of id-list arrayrefs, one per query in input order.
Each row is C<[x, y, r]> (2D) or C<[x, y, z, r]> (3D); a malformed row (not a 3- or
4-element arrayref, or a negative or non-finite C<r>) yields an B<empty list> for
that slot, siblings unaffected -- it cannot croak mid-batch while holding the lock,
mirroring C<insert_many>.  A region-too-large or out-of-memory condition from any
query still croaks (after freeing the partial result).  This is purely a
lock-amortization win for callers issuing many queries per critical section (for
example a per-tick collision broad-phase across many actors): one
C<rdlock>/C<rdunlock> pair for the batch instead of one per query.

=head3 Collision pairs

    $s->each_pair_within($max_r, sub { my ($va, $vb) = @_; ... });
    $s->each_colliding_pair(sub { my ($va, $vb) = @_; ... });

C<each_pair_within> invokes the callback once for every unordered pair of entries
whose centre distance is less than C<$max_r>.  C<each_colliding_pair> instead
pairs entries whose centre distance is less than the B<sum of their two radii>
(see C<set_radius>) -- a heterogeneous-radius collision test computed in a single
grid walk, so a small C<cell_size> stays correct even for large-radius entries.
Both emit each pair exactly once, are seam-aware in a toroidal world, and -- like
C<each_in_radius> -- snapshot under the read lock then run the callback with the
lock released (so it may mutate the map).  The callback arguments are the stored
B<values> of the pair.  Distances are 3D when any entry has a non-zero C<z> (or
the world wraps in C<z>), otherwise 2D.  C<each_pair_within> croaks on a negative
or non-finite C<$max_r>.

=head3 Region query cost

The cost of a region query scales with the number of grid cells covering
the query region, not with the number of matching points.  For
C<query_radius>, C<each_in_radius>, and each C<query_radius_many> sub-query that
is roughly S<(2 * radius / cell_size) ** dims> cells (similarly for C<query_aabb>,
which scans the cells spanning the box).  The scan runs while holding a
read lock.  An over-large radius relative to C<cell_size> therefore scans
many empty cells, wasting time and stalling concurrent writers that are
waiting for the lock.  Size C<cell_size> on the order of your typical
query radius so each query touches only a handful of cells.

As a safety net, any region query that would scan more than approximately
67 million cells (2**26) -- a C<query_radius>, C<query_aabb>,
C<each_in_radius>, or a C<query_radius_many> sub-query whose region spans that
many cells, a C<query_knn> that must walk that many cells across its expanding
shells, or a C<each_pair_within> / C<each_colliding_pair> whose per-entry
neighbourhood spans that many cells -- croaks with
a message containing the word "cells" rather than scanning unbounded.  If
your use case genuinely requires regions that large, increase C<cell_size>
so the same physical region maps to fewer cells.

=head2 Spherical worlds

For points on or above a sphere (planets, globes), construct with a body radius
and use the geo helpers; a separate cube-sphere scheme gives stable hierarchical
cell ids for chunking and level-of-detail.  Curvature needs no special handling:
with C<sphere> set, geo coordinates are converted to and from Cartesian in C, so
proximity is exact straight-line distance -- correct for surface and air entities
alike -- not a great-circle approximation.

=head3 Geo proximity

    my $s = Data::SpatialHash::Shared->new(undef, $max, 0, $cell, sphere => $R);

    my $h = $s->insert_geo($lat, $lon, $alt, $value);   # radians; alt above the surface
    $s->move_geo($h, $lat, $lon, $alt);
    my ($lat, $lon, $alt) = $s->position_geo($h);
    my @vals = $s->query_geo_radius($lat, $lon, $alt, $dist);   # $dist in world units

C<sphere> is the body radius -- distinct from a per-entry interaction radius --
and must be finite and greater than zero; it is stored in the map and restored
on reopen.  C<sphere> and C<wrap> are mutually exclusive (a sphere is not a flat
torus); passing both croaks.  Latitude and longitude are in B<radians> (C<lat>
in S<-pi/2 .. pi/2>, C<lon> in S<-pi .. pi>); C<alt> is height above the sphere
of radius C<$R>, so an entity lies at distance C<$R + $alt> from the centre.
Each geo method converts to Cartesian and delegates to the ordinary 3D engine,
so C<$dist> in C<query_geo_radius> is a true straight-line distance and must be
finite and non-negative.  At a pole, longitude is undefined and C<position_geo> reports it
as 0.  Calling a geo method on a map created without C<sphere> croaks.
C<insert_geo> returns a handle or C<undef> if the pool is exhausted (test with
C<defined> -- handle 0 is valid but false); C<move_geo> returns true, or false
for a freed/invalid handle; C<position_geo> croaks on a freed or invalid handle.

=head3 Cube-sphere cells

A direction (or lat/lon) maps to a hierarchical cell id on a cube-sphere: six
cube faces, each an equal-angle grid subdivided to a chosen B<level> (level 0 =
the whole face, level C<L> = C<2**L> cells per face edge, up to level 24).  The
ids are stateless integers independent of any stored data -- useful as chunk keys
for streaming and level-of-detail.

    my $cell = $s->cube_cell($x, $y, $z, $level);     # direction (need not be unit length)
    my $cell = $s->cube_cell_geo($lat, $lon, $level);
    my @adj  = $s->cube_neighbors($cell);             # 4 edge-adjacent cells, seam-aware
    my $up   = $s->cube_parent($cell);                # coarser cell (undef at level 0)
    my @kids = $s->cube_children($cell);              # 4 finer cells (empty at level 24)
    my $lvl  = $s->cube_level($cell);
    my ($x, $y, $z) = $s->cube_center($cell);         # cell centre as a unit vector
    my ($lat, $lon) = $s->cube_center_geo($cell);

A cell id packs C<(level, face, i, j)> into an unsigned integer, so cells at
different levels are different ids.  C<cube_neighbors> returns the four
edge-adjacent cells, correct across face seams; diagonal/corner neighbours are
not included.  These methods read no map state (any handle provides them), and a
malformed cell id croaks; a zero or non-finite direction yields an arbitrary but
valid cell.  The grid is near-uniform (equal-angle), not equal-area.

=head2 Introspection

    $s->count;        # live entry count
    $s->max_entries;  # capacity
    $s->num_buckets;  # bucket table size
    $s->cell_size;    # cell size in world units
    my @w = $s->world;  # wrap extents: (Wx,Wy) or (Wx,Wy,Wz); empty if not toroidal
    my $R = $s->sphere; # body radius (sphere => $R), or 0 if not a sphere map
    $s->stats;        # diagnostic hashref (see STATS)

=head2 Lifecycle

    $s->path;              # backing file path, or undef for anon/memfd
    $s->memfd;             # memfd fd (-1 for file-backed/anon)
    $s->sync;              # msync mmap to backing store
    $s->unlink;            # remove backing file
    Class->unlink($path);  # class-method form

C<sync> and C<unlink> croak on OS failure.

=head2 Event Loop Integration

    my $fd = $s->eventfd;         # lazy-create eventfd, returns fd
    $s->eventfd_set($fd);         # attach an external eventfd
    my $fd = $s->fileno;          # current eventfd fd, or -1
    $s->notify;                   # write 1 to eventfd (signal update)
    my $n = $s->eventfd_consume;  # read+reset eventfd counter

C<eventfd_set> attaches an external eventfd, closing the previously-attached fd
(such as one created by C<eventfd>) unless it is the same descriptor.
C<notify> returns false if no eventfd is attached, true after writing the
signal.  C<eventfd_consume> returns the counter as an integer, or C<undef> if
no eventfd is attached or nothing is pending (a spurious wakeup).

=head1 TUNING

Choose C<cell_size> close to your typical query radius.  A value too
small means many cells are scanned per radius query; a value too large
packs many entries into each cell and increases false-positive tests.

Choose C<num_buckets> to be a power of two slightly above the expected
peak live count; any value you pass is rounded up to the next power of
two.  The default (0 = auto) picks a power of two near C<max_entries>,
which is a safe starting point.  After loading real data, inspect
C<stats-E<gt>{load_factor}> (target below 0.7) and
C<stats-E<gt>{max_chain}> (target below 5).

=head1 BENCHMARKS

Measured on Linux x86_64, Perl 5.40.2 (F<bench/single.pl>).  The first four use
100k entries at C<cell_size> 1.0; C<each_colliding_pair> uses 4000 radius-bearing
actors on a 2000x2000 torus; the geo/cube rows use a planet (C<sphere> set):

    insert:                4.6M/s
    query_radius:           61k/s
    query_knn(10):         125k/s
    move:                  2.2M/s
    move_many:              22M/s    # ~10x move -- one lock acquisition per batch
    each_colliding_pair:   770/s     # ~1.3 ms per full broad-phase pass
    query_geo_radius:       12k/s    # planet proximity (lat/lon/alt -> 3D in C)
    cube_cell:             5.5M/s    # cube-sphere cell id (level 14)

=head1 STATS

C<stats()> returns a hashref with keys:

=over 4

=item C<count> -- current number of live entries

=item C<max_entries> -- allocated entry capacity

=item C<num_buckets> -- size of the bucket table

=item C<cell_size> -- cell size (float)

=item C<free_slots> -- available entry slots (max_entries - count)

=item C<occupied_buckets> -- number of buckets with at least one entry

=item C<max_chain> -- longest collision chain across all buckets

=item C<max_cell> -- most entries sharing a single grid cell

=item C<load_factor> -- count / num_buckets (float)

=item C<ops> -- total mutation operation counter

=item C<mmap_size> -- size of the shared mapping in bytes

=back

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> via a C<< mode => 0660 >> option to C<new>; the mode is applied
only when the file is created (an existing file keeps its own permissions). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head1 CRASH SAFETY

The write lock is a futex-based rwlock with PID-encoded ownership.
If the writer process dies while holding the lock, the next writer that
cannot acquire the lock checks whether the owner PID is still alive and,
if not, recovers the lock.  Reader slots are similarly reclaimed when
a dead reader's slot is detected.

B<Limitation>: PID reuse is not detected.  If a new process acquires
the same PID as a dead lock holder before recovery runs, the stale lock
may not be released automatically.  This edge case requires the kernel
to reassign PIDs faster than lock-recovery attempts, which is very
unlikely in practice but cannot be ruled out.

=head1 SEE ALSO

L<Data::Graph::Shared> - directed weighted graph

L<Data::Heap::Shared> - priority queue (for Dijkstra, Prim, etc.)

L<Data::Pool::Shared> - fixed-size object pool

L<Data::HashMap::Shared> - concurrent hash table

L<Data::Buffer::Shared> - typed shared array

L<Data::Queue::Shared> - FIFO queue

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log

L<Data::Sync::Shared> - synchronization primitives

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
