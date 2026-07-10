package Data::DisjointSet::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::DisjointSet::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

*same  = \&connected;
*merge = \&union;
*sets  = \&num_sets;
*clear = \&reset;

1;
__END__

=encoding utf-8

=head1 NAME

Data::DisjointSet::Shared - shared-memory union-find (disjoint-set) for Linux

=head1 SYNOPSIS

    use Data::DisjointSet::Shared;

    # a universe of 1000 elements (0 .. 999), anonymous shared mapping
    my $d = Data::DisjointSet::Shared->new(undef, 1000);

    $d->union(0, 1);          # merge the sets containing 0 and 1
    $d->union(1, 2);          # 0, 1, 2 are now one set
    $d->merge(3, 4);          # merge is an alias for union

    $d->connected(0, 2);      # true  -- same set
    $d->same(0, 3);           # false -- 'same' is an alias for connected
    $d->find(2);              # canonical representative (root) of 2's set
    $d->set_size(0);          # number of elements in 0's set (3)

    $d->num_sets;             # how many disjoint sets remain
    $d->capacity;             # the fixed element count (1000)

    # union many pairs in a single lock acquisition (flat [a0,b0,a1,b1,...])
    my $merged = $d->union_many([ 5,6, 6,7, 8,9 ]);   # returns how many merged

    $d->reset;                # back to all singletons (num_sets == capacity)

    # share across processes via a backing file
    my $shared = Data::DisjointSet::Shared->new("/tmp/dsu.bin", 1000);

=head1 DESCRIPTION

A union-find (disjoint-set) structure in shared memory. It maintains a
partition of a fixed universe of B<N integer elements> (numbered C<0 .. N-1>)
into disjoint sets. The three core operations are:

=over 4

=item *

B<union(a, b)> -- merge the set containing C<a> with the set containing C<b>
into a single set.

=item *

B<find(x)> -- return the I<canonical representative> (the root) of the set
containing C<x>. Two elements are in the same set if and only if they have the
same root.

=item *

B<connected(a, b)> -- test whether C<a> and C<b> are currently in the same set.

=back

The structure uses B<path compression> (path halving on C<find>) together with
B<union by size> (the larger-sized root always becomes the parent), which gives
near-constant amortized time per operation (the inverse-Ackermann bound). Each
element is one C<parent> slot and one C<size> slot, both 32-bit, so the payload
is C<8 * N> bytes regardless of how many unions are performed; the mapping also
carries a fixed ~16 KB cross-process reader table, so the C<mmap_size> stat
reports the true total.

Because the C<parent>/C<size> arrays live in a shared mapping, B<several
processes share one structure>: any process that opens the same backing file,
inherits the anonymous mapping across C<fork>, or reopens a passed memfd, sees
the others' unions and contributes its own. A write-preferring futex rwlock with
dead-process recovery guards every mutation, so unions from many processes
serialize cleanly and the final partition is well defined.

B<IMPORTANT:> C<find>, C<connected> and C<set_size> perform path compression --
they B<mutate> the structure to keep future queries fast -- and therefore
acquire the B<write lock>. They are I<not> read-only operations. Only
C<num_sets> and C<capacity> are cheap reads (C<capacity> is lock-free; it is
immutable after construction).

There is B<no> operation that unions one whole structure into another. A
disjoint-set is a partition of one fixed universe; combining it with a separate
structure is not meaningful. To combine elements, use C<union> or C<union_many>
within a single structure. B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $d = Data::DisjointSet::Shared->new($path, $n);
    my $d = Data::DisjointSet::Shared->new($path, $n, $mode);   # custom file mode
    my $d = Data::DisjointSet::Shared->new(undef, $n);          # anonymous
    my $d = Data::DisjointSet::Shared->new_memfd($name, $n);
    my $d = Data::DisjointSet::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$n> is the number of elements: the universe is C<0 .. $n-1>. It must be
C<E<gt>= 1> and C<E<lt>= 2**31>; C<new> and C<new_memfd> croak if C<$n> is out
of range. A freshly created structure starts with every element in its own
singleton set, so C<num_sets == $n> and C<set_size($i) == 1> for every C<$i>.

When reopening an existing file or memfd, the B<stored C<n> wins> and the
existing partition is preserved; the C<$n> you pass to C<new> on a reopen is
only used when the file is brand new. C<new_memfd> creates a Linux memfd
(transferable via its C<memfd> descriptor); C<new_from_fd> reopens one in
another process.

Backing files are created B<exclusively> (C<O_EXCL>, symlinks rejected) with
mode C<0600> by default, so only the creating user can attach. Pass an octal
C<$mode> (e.g. C<0664> or C<0666>, masked by the process umask) as the optional
third argument to permit group/other access for cross-user sharing. C<$mode>
applies only when the file is newly created; reopening an existing file never
changes its permissions.

=head2 Union and query

    my $merged = $d->union($a, $b);      # merge; 1 if newly merged, 0 if already together
    my $merged = $d->merge($a, $b);      # alias for union
    my $root   = $d->find($x);           # canonical representative of $x's set
    my $bool   = $d->connected($a, $b);  # true if $a and $b are in the same set
    my $bool   = $d->same($a, $b);       # alias for connected
    my $size   = $d->set_size($x);       # number of elements in $x's set

C<union> merges the set containing C<$a> with the set containing C<$b> and
returns B<1> if they were in B<different> sets (a merge happened, and
C<num_sets> decreased by one) or B<0> if they were B<already> in the same set
(nothing changed). C<merge> is a short alias.

C<find> returns the root of C<$x>'s set -- a stable representative that is equal
for all members of the same set. C<connected> (aliased C<same>) returns true
when C<$a> and C<$b> share a root. C<set_size> returns the number of elements in
C<$x>'s set.

All four of C<find>, C<connected>, C<set_size> and C<union> take the B<write
lock>: C<union> obviously mutates, and C<find>/C<connected>/C<set_size> mutate
via path compression. Every index argument must be in C<0 .. capacity-1>; an
out-of-range index croaks B<before> any lock is taken (so a caught croak never
leaks a lock).

=head2 Bulk union

    my $merged = $d->union_many(\@pairs);

C<union_many> takes an array reference of B<even length> holding a flat list of
pairs, C<[a0, b0, a1, b1, ...]>, and unions each consecutive C<(a, b)> pair
under a B<single> write lock. It returns the number of pairs that actually
caused a merge (i.e. the count of C<union> calls that would have returned 1).

The batch is B<atomic with respect to validation>: every index is resolved and
range-checked B<before> the lock is taken, so an odd-length array or any
out-of-range index croaks without performing C<any> union and without holding
the lock. An empty array reference is a valid no-op that performs zero unions.

=head2 Partition size

    my $sets = $d->num_sets;             # current number of disjoint sets
    my $sets = $d->sets;                 # alias for num_sets
    my $n    = $d->capacity;             # the fixed element count (immutable)

C<num_sets> (aliased C<sets>) is the current count of disjoint sets: it starts
equal to C<capacity> and decreases by one on each successful C<union>.
C<capacity> is the number of elements the structure was created with and never
changes. Both are read-only; C<capacity> is lock-free.

=head2 Lifecycle

    $d->reset;                           # back to all singletons
    $d->clear;                           # alias for reset
    $d->path; $d->memfd; $d->sync; $d->unlink;   # or Class->unlink($path)

C<reset> (aliased C<clear>) returns every element to its own singleton set, so
C<num_sets> becomes C<capacity> again. C<sync> flushes the mapping to its
backing store (a no-op for anonymous and memfd structures, which have none);
C<unlink> removes the backing file (also callable as C<< Class->unlink($path) >>);
C<path> returns the backing path (C<undef> for anonymous, memfd, or fd-reopened
structures) and C<memfd> the backing descriptor -- the memfd of a C<new_memfd>
structure or the dup'd fd of a C<new_from_fd> structure, and -1 for file-backed
or anonymous structures.

=head1 STATS

C<stats()> returns a hashref describing the structure:

=over 4

=item * C<capacity> -- the fixed number of elements (C<0 .. capacity-1>).

=item * C<sets> -- the current number of disjoint sets (C<num_sets>).

=item * C<ops> -- running count of operations that took the write lock
(C<union>, C<union_many>, C<find>, C<connected>, C<set_size>, C<reset>).

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The structure lives in a shared mapping, shared the same three ways as the rest
of the family: a B<backing file> (every process calls C<< new($path, $n) >> on
the same path; pass a C<$mode> to C<new> if the attaching processes run as
different users), an B<anonymous mapping inherited across C<fork>>, or a B<memfd>
whose descriptor is passed to an unrelated process (over a UNIX socket via
C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process unions
into and queries the same partition>. All mutation is serialized by the write
lock, so the final partition is independent of how the processes interleave.

    # parent and children share one disjoint-set with no coordination
    my $d = Data::DisjointSet::Shared->new(undef, 100);   # before fork
    unless (fork) { $d->union($_, $_ + 1) for 0 .. 49; exit }
    wait;
    print $d->num_sets, "\n";   # reflects the child's unions

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> as the last argument to C<new>; the mode is applied
only when the file is created (an existing file keeps its own permissions). The
file is opened with C<O_NOFOLLOW>, so a symlink planted at the path is refused,
and created with C<O_EXCL>; the on-disk header is validated when the file is
attached. Any process you grant write access to a shared mapping is trusted not
to corrupt its contents while other processes are using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Because C<union> updates a couple of words while holding the lock, a
crash leaves the partition consistent up to the last completed C<union>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::Histogram::Shared>, L<Data::CountMinSketch::Shared>,
L<Data::HyperLogLog::Shared>, L<Data::BloomFilter::Shared>,
L<Data::Intern::Shared>, L<Data::SortedSet::Shared>,
L<Data::SpatialHash::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
