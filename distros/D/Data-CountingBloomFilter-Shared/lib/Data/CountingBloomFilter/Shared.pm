package Data::CountingBloomFilter::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::CountingBloomFilter::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::CountingBloomFilter::Shared - shared-memory counting Bloom filter for Linux

=head1 SYNOPSIS

    use Data::CountingBloomFilter::Shared;

    # sized for 1_000_000 items at a 1% false-positive rate, anonymous mapping
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, 1_000_000, 0.01);

    $cbf->add("alice");
    $cbf->add("bob");

    $cbf->contains("alice");            # 1 (probably present)
    $cbf->contains("carol");            # 0 (definitely absent)

    # unlike a plain Bloom filter, you can delete
    $cbf->remove("alice");
    $cbf->contains("alice");            # 0

    # ...and read an occurrence count (0..15): how many times an item is stored
    $cbf->add("x"); $cbf->add("x");
    $cbf->count_of("x");                # 2

    # bulk add in a single lock acquisition
    my $n = $cbf->add_many([ map { "user-$_" } 1 .. 1000 ]);

    # share across processes via a backing file
    my $shared = Data::CountingBloomFilter::Shared->new("/tmp/seen.cbf", 1_000_000);

=head1 DESCRIPTION

A B<counting> Bloom filter in shared memory: like L<Data::BloomFilter::Shared>,
a compact fixed-size structure for B<approximate set membership>, but each
position is a small B<4-bit counter> instead of a single bit. That one change
buys two things a plain Bloom filter cannot do: you can B<remove> items, and you
can ask B<how many times> an item was added (C<count_of>). The cost is memory --
four bits per slot instead of one, so about B<four times> the size of the
equivalent Bloom filter.

Membership is still one-sided: C<contains> returns "definitely not present" or
"probably present". For items you have added (and not removed) it always returns
true -- there are B<no false negatives> -- with a small tunable rate of B<false
positives>. It never stores the items themselves, only which counters they touch.

Each item is hashed once with XXH3 (128-bit) and, by double hashing
(Kirsch-Mitzenmacher), drives C<k> probes into an array of C<m> counters. C<add>
increments each of the item's C<k> counters (saturating at 15); C<contains> is
true when B<all k> are greater than zero; C<remove> decrements them (only if the
item is present); and C<count_of> returns the B<minimum> of the C<k> counters --
an estimate of the item's stored occurrence count. From the requested capacity
C<n> and false-positive rate C<p> the filter derives C<k = round(-log2 p)> and
C<m = next_pow2(n * k / ln2)>, the same geometry as a Bloom filter.

The counters B<saturate at 15>: an item added more than 15 times (or colliding
with others up to that ceiling) sticks at 15 and is never decremented again,
which keeps membership sound (no false negatives) but caps C<count_of> and means
a saturated item cannot be fully removed. Sizing the filter for its intended load
keeps saturation vanishingly rare.

Because the table lives in a shared mapping, B<several processes share one
filter>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd sees the others' additions and
removals and contributes its own. A write-preferring futex rwlock with
dead-process recovery guards mutation, so many processes may C<add>, C<remove>,
and C<contains> concurrently.

B<Removal caveat.> C<remove> decrements the counters of an item that is present.
Because counters are shared between items, decrementing the counters of an item
that was B<never added> -- or one whose probes collide with present items -- can
push a shared counter to zero and cause a B<false negative> for some other item.
B<Only remove items you actually added>, and remove an item as many times as you
added it to forget it completely.

Items are added, tested, and removed by their B<byte> content; wide-character
strings (any codepoint above 255) cause a "Wide character" croak -- encode such
strings to bytes first (for example with C<Encode::encode_utf8>). B<Linux-only>.
Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $cbf = Data::CountingBloomFilter::Shared->new($path, $capacity, $fp_rate);
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, 1_000_000);        # anonymous, 1% default
    my $cbf = Data::CountingBloomFilter::Shared->new_memfd($name, $capacity, $fp_rate);
    my $cbf = Data::CountingBloomFilter::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$capacity> is the number of items you expect to add (at least 1). C<$fp_rate>
is the target false-positive rate at that capacity, strictly between 0 and 1
(default C<0.01>). C<new> and C<new_memfd> croak on a capacity below 1 or an
out-of-range C<$fp_rate>.

From C<$capacity> and C<$fp_rate> the filter derives C<k = round(-log2 fp_rate)>
(clamped to 1..32) probes and C<m = next_pow2(capacity * k / ln2)> 4-bit counters
(floor 64), for a C<m/2>-byte counter array. When reopening an existing file or
memfd the stored geometry wins and the caller's C<$capacity>/C<$fp_rate>
arguments are ignored. C<new_memfd> creates a Linux memfd (transferable via its
C<memfd> descriptor); C<new_from_fd> reopens one in another process.

An optional file B<mode> may be passed as the last argument to C<new> (e.g.
C<0660>) to opt a newly-created backing file into cross-user sharing; it defaults
to C<0600> (owner-only) and is ignored for anonymous mappings and existing files.

=head2 Adding, testing, counting, removing

    my $new   = $cbf->add($item);           # 1 if the item was probably new, else 0
    my $added = $cbf->add_many(\@items);     # count of adds that were probably new
    my $in    = $cbf->contains($item);       # 1 if probably present, 0 if definitely absent
    my $c     = $cbf->count_of($item);       # occurrence estimate 0..15
    my $gone  = $cbf->remove($item);         # 1 if present and decremented, else 0
    $cbf->clear;                             # reset to empty

C<add> hashes C<$item> (by its bytes; wide characters croak, encode first) and
increments its C<k> counters, each saturating at 15. It returns B<1 if the item
was probably new> (at least one of its counters was 0 beforehand) or B<0 if it
was already present>. C<add_many> takes an array reference and does the whole
batch under a single write lock, returning how many of the adds were probably new.

C<contains> returns B<1 if the item is probably present> (all C<k> counters are
nonzero) and B<0 if it is definitely absent>. A 0 means B<definitely absent>: an
item you added and have not removed never returns 0 (B<no false negatives>). A 1
may be a B<false positive>.

C<count_of> returns the B<minimum> of the item's C<k> counters, an integer from
B<0 to 15> estimating how many times the item is stored (times added minus
removed). Collisions can only raise a counter, so B<below saturation> C<count_of>
never under-counts -- it is an upper estimate. It B<saturates at 15>: a returned
15 means B<15 or more>, so an item added more than 15 times is under-reported. A
0 means definitely absent.

C<remove>, B<only if the item is present> (all C<k> counters are nonzero),
decrements each of them and returns B<1>; otherwise it changes nothing and
returns B<0>. Saturated (15) counters are B<left stuck>, so C<remove> of a
saturated item still returns 1 but cannot lower it -- a saturated item cannot be
fully removed. See the B<Removal caveat> in L</DESCRIPTION>: only remove items
you added, and remove an item as many times as it was added. C<clear> empties the
whole filter (all counters zeroed).

=head2 Merging

    $cbf->merge($other);                     # counter-wise saturating add

C<merge> adds another filter's counters into this one, counter by counter,
saturating each at 15. Both filters must have the B<same geometry> (same C<m> and
C<k>, i.e. created with the same capacity and false-positive rate) or C<merge>
croaks. The other filter is snapshotted under its own read lock, so two processes
may safely merge concurrently. After merging, C<contains> is true for every item
present in either filter and C<count_of> reflects the summed (saturated) counts.

=head2 Introspection and lifecycle

    $cbf->count; $cbf->capacity; $cbf->counters; $cbf->hashes; $cbf->fp_rate;
    $cbf->stats; $cbf->path; $cbf->memfd; $cbf->sync; $cbf->unlink;

C<count> estimates the number of B<distinct items currently present> (added minus
removed, from the fraction of nonzero counters, C<-(m/k) * ln(1 - X/m)> where
C<X> is the nonzero-counter count); it is an estimate, not an exact tally. C<capacity> is the configured item
capacity; C<counters> is the counter count C<m> (a power of two); C<hashes> is
C<k>; C<fp_rate> is the configured target false-positive rate. C<sync> flushes
the mapping to its backing store (a no-op for anonymous and memfd filters);
C<unlink> removes the backing file (also callable as C<< Class->unlink($path) >>);
C<path> returns the backing path (C<undef> for anonymous, memfd, or fd-reopened
filters) and C<memfd> the backing descriptor -- the memfd of a C<new_memfd>
filter or the dup'd fd of a C<new_from_fd> filter, and -1 for file-backed or
anonymous filters.

=head1 STATS

C<stats()> returns a hashref describing the filter:

=over 4

=item * C<capacity> -- the configured item capacity.

=item * C<fp_rate> -- the configured target false-positive rate.

=item * C<counters> -- the counter count C<m> (a power of two).

=item * C<hashes> -- the number of probes C<k> per item.

=item * C<counters_set> -- the number of nonzero counters.

=item * C<count> -- the estimated number of distinct items added.

=item * C<fill_ratio> -- C<counters_set / counters>, between 0 and 1. As this
approaches 1 the filter is saturating and the false-positive rate degrades.

=item * C<ops> -- running count of write-path calls (C<add>, C<add_many>,
C<remove>, C<merge>, C<clear>), whether or not any counter actually changed.

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The filter lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, ...) >> on the
same path with a matching capacity), an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> whose descriptor is passed to an unrelated process (over
a UNIX socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process adds
into, tests against, and removes from the same table>.

    # producer and consumer share one filter with no coordination
    my $cbf = Data::CountingBloomFilter::Shared->new(undef, 100_000);   # before fork
    unless (fork) { $cbf->add_many([ map { "ev-$_" } 1 .. 1000 ]); exit }
    wait;
    print $cbf->contains("ev-500") ? "seen\n" : "no\n";   # seen -- the child's add

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only the
creating user can open and attach them. To share a backing file across users,
pass an explicit octal file mode such as C<0660> as the last argument to C<new>;
the mode is applied when the file is created; a pre-existing B<empty> file owned
by the caller is adopted as new and likewise gets the requested mode, while a
B<non-empty> existing file keeps its own permissions. The file is opened with
C<O_NOFOLLOW>, so a symlink planted at the path is refused, and created with C<O_EXCL>; the on-disk header is validated when
the file is attached. Any process you grant write access to a shared mapping is
trusted not to corrupt its contents while other processes are using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Each C<add> and C<remove> is a short sequence of counter updates, so a
crash leaves the filter consistent up to the last completed operation.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

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

L<Data::BloomFilter::Shared> (membership without delete, one bit per slot),
L<Data::CuckooFilter::Shared> (membership with delete and C<count_of>, no
saturation caveat), L<Data::HyperLogLog::Shared>, and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
