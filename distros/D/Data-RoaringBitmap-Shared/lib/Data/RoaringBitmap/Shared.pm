package Data::RoaringBitmap::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::RoaringBitmap::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

*set       = \&add;
*test      = \&contains;
*delete    = \&remove;
*count     = \&cardinality;
*size      = \&cardinality;
*or        = \&union;
*and       = \&intersect;

1;
__END__

=encoding utf-8

=head1 NAME

Data::RoaringBitmap::Shared - shared-memory Roaring bitmap (compressed uint32 set) for Linux

=head1 SYNOPSIS

    use Data::RoaringBitmap::Shared;

    # anonymous shared mapping: a 256-slot container pool
    my $a = Data::RoaringBitmap::Shared->new(undef, 256);

    $a->add(5);              # 1 (newly added)
    $a->add(5);              # 0 (already present)
    $a->contains(5);         # true   ('test' is an alias)
    $a->remove(5);           # 1 (removed; 'delete' is an alias)

    $a->add_many([1, 2, 3, 1000, 70000]);   # returns count newly added
    $a->cardinality;         # number of elements  ('count'/'size' are aliases)
    $a->min; $a->max;        # smallest / largest element (undef if empty)
    my $list = $a->to_array; # arrayref of every element, ascending

    # in-place set operations against another bitmap
    my $b = Data::RoaringBitmap::Shared->new(undef, 256);
    $b->add_many([3, 4, 5]);
    $a->union($b);           # a |= b   ('or' is an alias);  returns $a
    $a->intersect($b);       # a &= b   ('and' is an alias);  returns $a

    # share across processes via a backing file
    my $shared = Data::RoaringBitmap::Shared->new("/tmp/ids.bin", 65536);

=head1 DESCRIPTION

A B<Roaring bitmap> in shared memory: a compressed set of 32-bit unsigned
integers. The 32-bit value space is split into B<65536 buckets> keyed by the
high 16 bits of each value; each bucket stores the low 16 bits of its members in
one of two container kinds, chosen automatically by density:

=over 4

=item *

an B<array container> -- a sorted ascending C<uint16> array, compact when the
bucket is B<sparse> (up to 4096 elements);

=item *

a B<bitmap container> -- a 65536-bit bitmap, efficient when the bucket is
B<dense>.

=back

A bucket starts as an array and is B<promoted to a bitmap> once it would exceed
B<4096> elements. Both kinds occupy one fixed 8192-byte slot from a container
pool, so the structure stays compact for sparse, clustered, and dense sets
alike. It supports membership tests, cardinality, C<min>/C<max>, C<to_array>,
and B<in-place> C<union> and C<intersect> with another bitmap.

Because the bucket table and container pool live in a shared mapping, B<several
processes share one bitmap>: any process that opens the same backing file,
inherits the anonymous mapping across C<fork>, or reopens a passed memfd, sees
the others' elements. A write-preferring futex rwlock with dead-process recovery
guards every mutation, so concurrent adds, removals, and set operations
serialize cleanly.

B<Values must fit in 32 bits> (0 .. 4294967295); a value outside that range
croaks on C<add>/C<add_many> and is simply absent for C<contains>/C<remove>.

B<v1 scope:> array + bitmap containers (B<no run containers>); B<union and
intersect only> (no C<xor> / C<andnot> yet); a bitmap container is B<not>
down-converted back to an array when removals make it sparse again.

B<Capacity is fixed at creation.> The container pool holds C<container_capacity>
slots; C<add>, C<add_many> and C<union> croak (after releasing the lock) when
the pool is exhausted. A bitmap that touches every bucket as a dense bitmap
needs all 65536 slots (512 MiB of pool); a sparse set needs far fewer.
B<Linux-only.> Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $a = Data::RoaringBitmap::Shared->new($path, $container_capacity);
    my $a = Data::RoaringBitmap::Shared->new(undef, $container_capacity); # anonymous
    my $a = Data::RoaringBitmap::Shared->new_memfd($name, $container_capacity);
    my $a = Data::RoaringBitmap::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$container_capacity> (default 256) is the number of 8192-byte container slots
the pool holds; it must be C<E<gt>= 1> and C<E<lt>= 2**20>. One slot is consumed
per non-empty bucket (a bucket is one container regardless of whether it is an
array or a bitmap), so size the pool for the number of distinct high-16 groups
your values fall into, with headroom. C<new> and C<new_memfd> croak if the
capacity is out of range. A freshly created bitmap is empty
(C<cardinality == 0>).

When reopening an existing file or memfd, the B<stored geometry wins> and the
existing elements are preserved; the capacity you pass to C<new> on a reopen is
used only when the file is brand new. C<new_memfd> creates a Linux memfd
(transferable via its C<memfd> descriptor); C<new_from_fd> reopens one in
another process.

=head2 Adding and removing

    my $new   = $a->add($x);          # 1 if newly added, 0 if already present
    my $new   = $a->set($x);          # alias for add
    my $added = $a->add_many(\@ints); # count of elements newly added
    my $gone  = $a->remove($x);       # 1 if removed, 0 if absent
    my $gone  = $a->delete($x);       # alias for remove

C<add> (aliased C<set>) inserts C<$x>, returning B<1> if it was new or B<0> if it
was already present. C<$x> must be an unsigned integer that B<fits in 32 bits>;
a larger value croaks B<before> any lock is taken. C<add> croaks if the
container pool is exhausted (only adding to a brand-new bucket can need a slot);
the croak happens B<after> the write lock is released and the bitmap is left
consistent.

C<add_many> adds every value of the array reference (each range-checked up front;
an out-of-range value croaks before any lock). It returns the number of elements
that were B<newly added>. B<It is not atomic on pool exhaustion:> values are
added in order, and if the pool runs out partway, C<add_many> croaks with the
already-processed elements left as members (a set is order-independent, so the
added ones are simply present).

C<remove> (aliased C<delete>) removes C<$x>, returning B<1> if it was present or
B<0> if it was absent (an out-of-range value is treated as absent). When the
last element of a bucket is removed, the bucket's container slot is returned to
the pool. As noted in L</DESCRIPTION>, a bitmap container is not converted back
to an array on removal in v1.

=head2 Membership, cardinality, ordering

    my $bool = $a->contains($x);   # true if $x is a member
    my $bool = $a->test($x);       # alias for contains
    my $n    = $a->cardinality;    # number of elements
    my $n    = $a->count;          # alias for cardinality
    my $n    = $a->size;           # alias for cardinality
    my $bool = $a->is_empty;       # true when cardinality == 0
    my $lo   = $a->min;            # smallest element, or undef if empty
    my $hi   = $a->max;            # largest element, or undef if empty
    my $list = $a->to_array;       # arrayref of all elements, ascending

C<contains> (aliased C<test>) is a read; an out-of-range value is simply not a
member. C<cardinality> (aliased C<count>/C<size>) is the total number of
elements across all buckets. C<min> and C<max> scan for the smallest/largest
member and return C<undef> on an empty set. C<to_array> returns a reference to a
new array holding every element in B<ascending order>; for a large dense set
this can be a long list. (The array is pre-sized under a brief read lock and
filled under the read lock; it is a best-effort snapshot if the set is being
mutated concurrently.)

=head2 Set operations (in place)

    $a->union($other);       # a |= b  (set union);        returns $a
    $a->or($other);          # alias for union
    $a->intersect($other);   # a &= b  (set intersection);  returns $a
    $a->and($other);         # alias for intersect

C<union> (aliased C<or>) adds every element of C<$other> to the receiver;
C<intersect> (aliased C<and>) keeps only the elements present in both. Both
B<modify the receiver in place> and return it (so calls chain). C<$other> must
be a C<Data::RoaringBitmap::Shared> object; combining a bitmap with itself
(C<< $a->union($a) >>) is a no-op.

C<union> may need new container slots (one per bucket that C<$other> occupies and
the receiver does not); it pre-checks capacity and croaks B<before mutating>
(after releasing the locks) if the pool cannot satisfy the operation, leaving the
receiver unchanged. C<intersect> only ever shrinks or frees containers, so it
never needs new slots and never croaks for capacity.

B<Locking note:> a set operation takes the receiver's B<write lock> and
C<$other>'s B<read lock>. To stay deadlock-free even if two processes run
C<< $a->union($b) >> and C<< $b->union($a) >> simultaneously, the two locks are
acquired in a fixed order keyed on a per-bitmap identity stored in shared
memory (so both processes compute the same order regardless of how the handles
happen to be laid out in each process), and the receiver always takes the write
lock. Calling a set op with two handles to the same underlying bitmap (the same
object, or a second handle that reopened the same backing file or memfd) is
detected and is a no-op.

=head2 Lifecycle

    $a->clear;                                  # remove every element
    $a->path; $a->memfd; $a->sync; $a->unlink;  # or Class->unlink($path)

C<clear> empties the bitmap and returns every container slot to the pool.
C<sync> flushes the mapping to its backing store (a no-op for anonymous and
memfd bitmaps); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened bitmaps) and C<memfd> the backing descriptor --
the memfd of a C<new_memfd> bitmap or the dup'd fd of a C<new_from_fd> bitmap,
and -1 for file-backed or anonymous bitmaps.

=head1 STATS

C<stats()> returns a hashref describing the bitmap:

=over 4

=item * C<cardinality> -- the total number of elements (same as C<cardinality>).

=item * C<containers_used> -- the 1-based high-water of container slots allocated
since creation or the last C<clear> (slot 0 is the reserved NULL sentinel, so an
empty pool reports 1).

=item * C<containers_capacity> -- the fixed container-pool capacity.

=item * C<buckets_used> -- the number of non-empty buckets (each is one
container, array or bitmap).

=item * C<ops> -- running count of mutating operations
(C<add>, C<add_many>, C<remove>, C<union>, C<intersect>, C<clear>).

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The bitmap lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, ...) >> on the
same path), an B<anonymous mapping inherited across C<fork>>, or a B<memfd>
whose descriptor is passed to an unrelated process (over a UNIX socket via
C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process adds to
and queries the same bitmap>. All mutation is serialized by the write lock, so
the final contents are independent of how the processes interleave.

    # parent and children share one bitmap with no coordination
    my $a = Data::RoaringBitmap::Shared->new(undef, 65536);   # before fork
    unless (fork) { $a->add($_) for 1 .. 100000; exit }
    wait;
    print $a->cardinality, "\n";   # reflects the child's adds

=head1 SECURITY

Backing files are created mode C<0600> (owner-only) by default; opt in to
cross-user sharing by passing a wider file mode as the last argument to C<new>. Reads and writes
bound-check the file-stored container offsets and counts, so reopening a crafted
or corrupted backing file cannot drive an out-of-bounds access. A process
granted write access to a shared mapping is still trusted not to corrupt the
structure while other processes are actively using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Because every mutation performs its container allocations under the
lock after a capacity pre-check, a crash leaves the bitmap consistent up to the
last completed operation. B<Limitation>: PID reuse is not detected (very
unlikely in practice).

=head1 SEE ALSO

L<Data::RadixTree::Shared>, L<Data::DisjointSet::Shared>,
L<Data::Intern::Shared>, L<Data::SortedSet::Shared>,
L<Data::SpatialHash::Shared>, L<Data::Histogram::Shared>,
L<Data::CountMinSketch::Shared>, L<Data::HyperLogLog::Shared>,
L<Data::BloomFilter::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
