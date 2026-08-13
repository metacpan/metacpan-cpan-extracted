package Data::SegmentTree::Shared;
use strict;
use warnings;
our $VERSION = '0.04';
require XSLoader;
XSLoader::load('Data::SegmentTree::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::SegmentTree::Shared - shared-memory segment tree (range add/assign,
range sum/min/max/gcd/product)

=head1 SYNOPSIS

    use Data::SegmentTree::Shared;

    # an array of 1000 signed-integer positions, all 0
    my $st = Data::SegmentTree::Shared->new(undef, 1000);

    $st->set(10, 42);              # position 10 := 42
    $st->add(10, 5);               # position 10 += 5  (now 47)
    $st->range_add(0, 99, 3);      # add 3 to every position in [0, 99]
    $st->range_assign(0, 99, 7);   # set every position in [0, 99] to 7

    my $s = $st->sum(0, 99);       # sum over a range
    my $lo = $st->min(0, 99);      # minimum over a range
    my $hi = $st->max(0, 99);      # maximum over a range
    my $q = $st->query(0, 99);     # { sum, min, max, count } in one call
    my $g = $st->gcd(0, 99);       # gcd over a range   (assign/set-only trees)
    my $p = $st->product(0, 99);   # product over a range (assign/set-only trees)

    # share the array across processes via a backing file
    my $shared = Data::SegmentTree::Shared->new("/tmp/array.st", 1000);

=head1 DESCRIPTION

A B<segment tree> in shared memory: a fixed array of C<n> signed 64-bit integer
positions that supports B<range updates and range queries> in O(log n) each --
add a delta to every element of a range, and query the sum, minimum, or maximum
of any range. It complements L<Data::Fenwick::Shared> (which does prefix sums and
point updates): a segment tree adds B<range minimum and maximum> queries and
B<range add> (via lazy propagation), neither of which a Fenwick tree can do.

The tree is a perfect binary tree over C<next_pow2(n)> leaves; each node caches
its subtree's sum, min, and max, plus a pending "range add" delta that is pushed
down lazily. Range updates and queries therefore touch only O(log n) nodes.
Positions start at 0 and are addressed by a 0-based index; out-of-range indices
croak.

Because the tree lives in a shared mapping, B<several processes update and query
one array>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd sees the same array. A
write-preferring futex rwlock with dead-process recovery guards mutation; queries
never mutate the tree, so they take only the read lock and many can run at once.
B<Linux-only>. Requires 64-bit Perl.

Values and range sums are signed 64-bit integers; a range sum that exceeds the
64-bit range overflows (wraps), as with any native integer accumulator.

=head2 Range assign and the gcd/product monoids

Alongside C<range_add>, the tree supports B<range_assign> -- set every position in
a range to a constant in O(log n) (a second lazy tag, composed correctly with
C<range_add>). It also offers two extra range monoids, B<gcd> and B<product>.

These monoids come with a hard mathematical restriction: B<gcd and product cannot
be maintained under C<range_add>> (there is no way to recover the gcd or product
of C<{a+d, b+d, ...}> from the gcd/product of C<{a, b, ...}>). So C<gcd> and
C<product> are exact only while the tree has seen B<assign/set updates only>; the
first C<range_add> or C<add> B<permanently gates them off> (C<gcd>/
C<product> then croak until C<clear>). Use C<< $st->monoids_valid >> to check.
Point updates via C<set> use assign internally, so they keep the monoids valid.
C<product> additionally croaks if the product of the queried range overflows a
signed 64-bit integer.

B<On-disk format>: the on-disk layout changes between releases (0.02 widened the
node to carry the assign tag and the gcd/product aggregates; 0.03 added the
reader-slots lock's occupancy bitmap), so a B<file written by an older release is
rejected on attach> -- rebuild it. These trees are normally ephemeral compute
structures, so this only matters if you persisted one.

=head1 METHODS

=head2 Constructors

    my $st = Data::SegmentTree::Shared->new($path, $n, $mode);
    my $st = Data::SegmentTree::Shared->new(undef, $n);            # anonymous
    my $st = Data::SegmentTree::Shared->new_memfd($name, $n);
    my $st = Data::SegmentTree::Shared->new_from_fd($fd);

C<$n> is the number of positions (at least 1, up to 2^24); every position
starts at 0. Memory is C<2 * next_pow2(n) * 64> bytes plus a fixed header.
C<new> and C<new_memfd> croak on a C<$n> below 1 or above 2^24. When reopening
an existing file or memfd the stored C<$n> wins and the caller's arguments do
not resize it -- but they are still range-checked, so an out-of-range value
croaks. An optional file B<mode> may be passed as the last argument to C<new>
(e.g. C<0660>) for cross-user sharing; it defaults to C<0600> (owner-only).

=head2 Updates

    $st->set($i, $value);              # position $i := $value
    my $new = $st->add($i, $delta);     # position $i += $delta; returns the new value
    $st->range_add($l, $r, $delta);     # add $delta to every position in [$l, $r]
    $st->range_assign($l, $r, $value);  # set every position in [$l, $r] to $value

C<set> assigns a single position; C<add> adds a delta to a single position and
returns its new value; C<range_add> adds a delta to every position in the
inclusive range C<[$l, $r]>, and C<range_assign> sets every position in the range
to a constant -- each in O(log n) via lazy propagation. All indices are 0-based
and croak if out of range; the range forms croak if C<$l > $r>.
C<range_add>/C<add> gate off the gcd/product monoids (see below); C<set>/
C<range_assign> do not.

=head2 Queries

    my $v = $st->get($i);          # value at position $i
    my $s = $st->sum($l, $r);      # sum over [$l, $r]
    my $lo = $st->min($l, $r);     # minimum over [$l, $r]
    my $hi = $st->max($l, $r);     # maximum over [$l, $r]
    my $q = $st->query($l, $r);    # { sum, min, max, count } in one locked call
    my $g = $st->gcd($l, $r);      # gcd over [$l, $r]     (assign/set-only trees)
    my $p = $st->product($l, $r);  # product over [$l, $r] (assign/set-only trees)

C<get> returns a single position's value. C<sum>, C<min>, and C<max> return one
aggregate over the inclusive range C<[$l, $r]>. C<query> returns all of them at
once as a hash reference C<< { sum, min, max, count } >> (C<count> is
C<$r - $l + 1>), computed under a single read lock so the four values are
mutually consistent. C<gcd> returns the greatest common divisor of C<|values|>
over the range (0 for an all-zero range), and C<product> returns their product;
both require an B<assign/set-only> tree and croak once any C<range_add>/C<add> has run
(see L</"Range assign and the gcd/product monoids">), and C<product> also croaks
on 64-bit overflow. Ranges croak if an index is out of range or C<$l > $r>.

=head2 Introspection and lifecycle

    $st->size;          # n, the number of positions
    $st->monoids_valid; # true if gcd/product are still usable (no range_add yet)
    $st->clear;         # reset every position to 0
    $st->stats;         # { n, size, tree_size, ops, mmap_size }
    $st->path; $st->memfd; $st->sync; $st->unlink;

C<monoids_valid> reports whether C<gcd>/C<product> are currently usable (false once
a C<range_add>/C<add> has gated them off). C<clear> resets every position to 0 and
re-enables the monoids. C<sync> flushes the mapping to its backing
store (a no-op for anonymous and memfd trees); C<unlink> removes the backing file
(also callable as C<< Class->unlink($path) >>); C<path> returns the backing path
(C<undef> for anonymous, memfd, or fd-reopened trees) and C<memfd> the backing
descriptor. The descriptor C<memfd> returns is B<owned by the object> and closed
when the object is destroyed; do not close it yourself. Pass it to another process
(or C<new_from_fd>) while the object is still alive.

=head1 SHARING ACROSS PROCESSES

The tree lives in a shared mapping, exposed the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> passed to an unrelated process and reopened with C<<
new_from_fd($fd) >>. The descriptor you pass is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the handle. Every process's updates land in the one shared array, and
queries take only the read lock so many readers proceed concurrently.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing (the mode is masked to the permission bits C<0777>). The file is opened
with C<O_NOFOLLOW> and C<O_EXCL>, and the header is validated on attach. Any
process granted write access is trusted not to corrupt the mapping.

A descriptor passed to C<new_from_fd> must be B<resize-sealed> (a C<memfd> sealed
against C<F_SEAL_SHRINK>|C<F_SEAL_GROW>, as C<new_memfd> produces) or come from a
trusted owner: a hostile donor that truncates the fd after it is mapped can fault
the reader with C<SIGBUS> on a later access. C<new_from_fd> rejects a sealable fd
that lacks both resize seals; a non-sealable fd (e.g. a regular file) cannot carry
seals and is accepted on the caller's trust.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Dead-owner recovery restores lock
B<availability> only. Each mutation is a multi-store O(log n) tree walk with no
commit protocol, so a writer killed mid-update leaves that update partially
applied: the tree can be left internally inconsistent (a later C<query> may
disagree with the individual C<get> values), and recovery neither detects nor
repairs the torn update. Treat a crash during a mutation as leaving the tree in
an undefined state, and rebuild from a trusted source if you need consistency
across crashes. B<Limitation>: PID reuse is not detected (very unlikely in
practice).

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
apart from a corrupt one and C<new> croaks with C<incomplete segment-tree file
left by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 SEE ALSO

L<Data::Fenwick::Shared> (prefix sums / point updates), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
