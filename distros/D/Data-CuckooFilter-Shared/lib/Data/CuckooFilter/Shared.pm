package Data::CuckooFilter::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::CuckooFilter::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::CuckooFilter::Shared - shared-memory Cuckoo filter for Linux

=head1 SYNOPSIS

    use Data::CuckooFilter::Shared;

    # sized for 1_000_000 items, anonymous mapping
    my $cf = Data::CuckooFilter::Shared->new(undef, 1_000_000);

    $cf->add("alice");
    $cf->add("bob");

    $cf->contains("alice");             # 1 (probably present)
    $cf->contains("carol");             # 0 (definitely absent)

    # unlike a Bloom filter, you can delete
    $cf->remove("alice");
    $cf->contains("alice");             # 0

    # occurrence count (0..8): how many copies of an item are stored
    $cf->add("x"); $cf->add("x");
    $cf->count_of("x");                 # 2

    # add returns 0 when the table is full (a true no-op)
    my $ok = $cf->add("item");          # 1 if stored, 0 if full

    # bulk add in a single lock acquisition
    my $n = $cf->add_many([ map { "user-$_" } 1 .. 1000 ]);

    # share across processes via a backing file
    my $shared = Data::CuckooFilter::Shared->new("/tmp/seen.cuckoo", 1_000_000);

=head1 DESCRIPTION

A Cuckoo filter in shared memory: a compact, fixed-size structure for
B<approximate set membership> that, unlike a Bloom filter, B<supports delete>.
You add items, ask whether an item is present, and remove items you previously
added. The membership answer is either "definitely not present" or "probably
present": for items you have added (and not removed) C<contains> always returns
true -- there are B<no false negatives> -- but there is a tiny rate of B<false
positives> (it may occasionally report an item as present that was never added).
It never stores the items themselves, only a small fingerprint of each, so
memory is proportional to the configured capacity, not to the size of the items.

Each item is hashed once with XXH3 (128-bit). The high half yields a 16-bit
B<fingerprint>; the low half yields one candidate bucket, and partial-key cuckoo
hashing derives a second candidate bucket from the first and the fingerprint.
Each bucket holds four fingerprint slots. C<add> stores the fingerprint in
either candidate bucket, evicting and rehoming existing fingerprints (the
"cuckoo" kick) when both are full. The false-positive rate is governed by the
fingerprint width and bucket size and is approximately C<2 * slots_per_bucket /
2**16> -- about 0.012% with the fixed 16-bit fingerprint and 4-slot buckets.

The filter has a B<bounded capacity>. When both candidate buckets are full and a
bounded sequence of cuckoo evictions cannot rehome a fingerprint, C<add> returns
false and leaves the filter B<byte-for-byte unchanged> -- a failed insert is a
true no-op, so it never drops a previously stored fingerprint and never creates
a false negative, even at the full boundary. A real-world filter accepts roughly
its configured capacity (typically B<95% or more>) before reporting full.

Because the table lives in a shared mapping, B<several processes share one
filter>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd, sees the others' additions
and removals and contributes its own. A write-preferring futex rwlock with
dead-process recovery guards mutation, so many processes may C<add>, C<remove>,
and C<contains> concurrently.

B<Removal caveat.> C<remove> deletes one fingerprint matching the item. Because
the filter stores only a 16-bit fingerprint, removing an item that was B<never
added> -- or one whose fingerprint happens to collide with a different present
item -- may delete the B<wrong> fingerprint and corrupt the filter (causing a
false negative for some other item). B<Only remove items you actually added.>
There is no de-duplication: re-adding an item stores a B<second> copy of its
fingerprint (and C<count> rises by one each time), so to fully forget an item
you must C<remove> it as many times as you added it. Cuckoo filters do not union
cleanly, so there is B<no merge> operation.

Items are added, tested, and removed by their B<byte> content; wide-character
strings (any codepoint above 255) cause a "Wide character" croak -- encode such
strings to bytes first (for example with C<Encode::encode_utf8>). B<Linux-only>.
Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $cf = Data::CuckooFilter::Shared->new($path, $capacity);
    my $cf = Data::CuckooFilter::Shared->new(undef, 1_000_000);   # anonymous
    my $cf = Data::CuckooFilter::Shared->new_memfd($name, $capacity);
    my $cf = Data::CuckooFilter::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$capacity> is the number of items you expect to add; it must be at least 1.
C<new> and C<new_memfd> croak if C<$capacity> is less than 1.

From C<$capacity> the filter derives its geometry: a bucket array of
C<num_buckets = next_power_of_two(ceil(capacity / 4 / 0.95))> buckets (floor 2),
each with four 16-bit fingerprint slots, for C<4 * num_buckets> slots total. The
0.95 target load factor and the rounding up to a power of two mean the realised
capacity at the full boundary is typically B<at or above> the requested
C<$capacity>. When reopening an existing file or memfd, the stored geometry wins
and the caller's C<$capacity> argument is ignored. C<new_memfd> creates a Linux
memfd (transferable via its C<memfd> descriptor); C<new_from_fd> reopens one in
another process.

=head2 Adding, testing, removing

    my $ok    = $cf->add($item);            # 1 if stored, 0 if the table is full
    my $added = $cf->add_many(\@items);     # count of items stored
    my $in    = $cf->contains($item);       # 1 if probably present, 0 if definitely absent
    my $c     = $cf->count_of($item);       # occurrence count 0..8 (times added minus removed)
    my $gone  = $cf->remove($item);         # 1 if a fingerprint was removed, else 0
    $cf->clear;                             # reset to empty

C<add> hashes C<$item> (taken by its bytes; wide characters croak, encode first)
and stores its fingerprint in one of its two candidate buckets, returning B<1 on
success>. It returns B<0 only when the table is full> -- both candidate buckets
are occupied and a bounded run of cuckoo evictions could not make room. A return
of 0 is a true B<no-op>: the filter is unchanged, so nothing you previously
added is lost (B<no false negatives for added items>, even when full). C<add>
does B<not> de-duplicate: adding the same item twice stores its fingerprint
twice and increments C<count> by two. C<add_many> takes an array reference and
does the whole batch under a single write lock, returning how many elements were
stored (the count of C<add> calls that returned 1).

C<contains> returns B<1 if the item is probably present> and B<0 if it is
definitely absent>. A 0 means B<definitely absent>: an item you added and have
not removed will never return 0 (there are B<no false negatives>). A 1 may be a
B<false positive> (a different item happens to share a fingerprint and bucket).
There are B<never false negatives> for items that are currently stored.

C<count_of> returns B<how many copies of C<$item> are stored> -- the number of
times it was added minus the number of times it was removed -- as an integer
from B<0 to 8>. Because a fingerprint can live only in its two candidate buckets
(four slots each), the count B<saturates at 8> (C<2 * slots_per_bucket>): once an
item fills those slots a further C<add> of it returns 0 (full). Like C<contains>
it is probabilistic -- 0 means B<definitely absent>, while a positive count is an
estimate that a colliding fingerprint can inflate (the same caveat as C<remove>:
trust it only for items you added). It takes a read lock and is safe to call
concurrently. This makes the filter usable as a small B<counting> set (counts
below 8) without the extra memory of a counting Bloom filter.

C<remove> deletes one stored fingerprint of C<$item>, returning B<1 if one was
found and cleared> or B<0 if none matched>. See the B<Removal caveat> in
L</DESCRIPTION>: only remove items you added, and remove an item as many times
as it was added to forget it completely. C<clear> empties the whole filter
(all slots zeroed, C<count> reset to 0).

=head2 Introspection and lifecycle

    $cf->count; $cf->capacity; $cf->buckets; $cf->slots; $cf->stats;
    $cf->path; $cf->memfd; $cf->sync; $cf->unlink;   # or Class->unlink($path)

C<count> is the number of fingerprints currently stored (maintained exactly on
every C<add>, C<remove>, and C<clear>); since C<add> stores duplicates, this is
the number of live fingerprints, not the number of distinct items. C<capacity>
is the configured item capacity; C<buckets> is the bucket count (a power of two);
C<slots> is the total fingerprint-slot count (C<4 * buckets>). C<sync> flushes
the mapping to its backing store (a no-op for anonymous and memfd filters);
C<unlink> removes the backing file (also callable as C<< Class->unlink($path) >>);
C<path> returns the backing path (C<undef> for anonymous, memfd, or fd-reopened
filters) and C<memfd> the backing descriptor -- the memfd of a C<new_memfd>
filter or the dup'd fd of a C<new_from_fd> filter, and -1 for file-backed or
anonymous filters.

There is deliberately B<no merge> method: cuckoo filters cannot be unioned by a
simple element-wise operation the way Bloom filters can.

=head1 STATS

C<stats()> returns a hashref describing the filter:

=over 4

=item * C<capacity> -- the configured item capacity.

=item * C<buckets> -- the bucket count (a power of two).

=item * C<slots> -- the total number of fingerprint slots (C<4 * buckets>).

=item * C<count> -- the number of fingerprints currently stored.

=item * C<fill_ratio> -- C<count / slots>, between 0 and 1. As this approaches 1
the table is near full and C<add> begins to fail; in practice inserts start to
fail somewhat below a full table.

=item * C<ops> -- running count of write-path calls (C<add>, C<add_many>,
C<remove>, C<clear>), whether or not any fingerprint was actually stored or
removed.

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The filter lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, ...) >> on the
same path with a matching capacity), an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> whose descriptor is passed to an unrelated process (over
a UNIX socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process adds
into, tests against, and removes from the same table>, so membership reflects
the combined effect of what all of them have done.

    # producer and consumer share one filter with no coordination
    my $cf = Data::CuckooFilter::Shared->new(undef, 100_000);   # before fork
    unless (fork) { $cf->add_many([ map { "ev-$_" } 1 .. 1000 ]); exit }
    wait;
    print $cf->contains("ev-500") ? "seen\n" : "no\n";   # seen -- the child's add

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
recovers. Each C<add> commits with a single fingerprint store (or, on the
eviction path, an all-or-nothing sequence that rolls back on failure), so a
crash leaves the filter consistent up to the last completed operation.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::BloomFilter::Shared> (membership without delete),
L<Data::HyperLogLog::Shared>, L<Data::Intern::Shared>,
L<Data::SortedSet::Shared>, L<Data::SpatialHash::Shared>, and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
