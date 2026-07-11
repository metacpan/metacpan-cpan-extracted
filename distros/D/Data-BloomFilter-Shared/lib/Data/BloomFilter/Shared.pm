package Data::BloomFilter::Shared;
use strict;
use warnings;
our $VERSION = '0.03';
require XSLoader;
XSLoader::load('Data::BloomFilter::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::BloomFilter::Shared - shared-memory Bloom filter for Linux

=head1 SYNOPSIS

    use Data::BloomFilter::Shared;

    # sized for 1_000_000 items at a 1% false-positive rate, anonymous mapping
    my $bf = Data::BloomFilter::Shared->new(undef, 1_000_000, 0.01);

    $bf->add("alice");
    $bf->add("bob");

    $bf->contains("alice");             # 1 (probably present)
    $bf->contains("carol");             # 0 (definitely absent)

    # "have I seen this before?" -- add returns 1 the first time, 0 after
    my $first = $bf->add("event-42");   # 1: probably new
    my $again = $bf->add("event-42");   # 0: all its bits were already set

    # bulk add in a single lock acquisition
    my $new = $bf->add_many([ map { "user-$_" } 1 .. 1000 ]);

    # merge another filter of identical geometry (bitwise OR -> union)
    my $other = Data::BloomFilter::Shared->new(undef, 1_000_000, 0.01);
    $other->add_many([ map { "user-$_" } 500 .. 1500 ]);
    $bf->merge($other);

    # share across processes via a backing file
    my $shared = Data::BloomFilter::Shared->new("/tmp/seen.bloom", 1_000_000, 0.01);

=head1 DESCRIPTION

A Bloom filter in shared memory: a compact, fixed-size structure for
B<probabilistic set membership>. You add items to it, then ask whether an item
is in the set. The answer is either "definitely not present" or "probably
present": the filter has B<no false negatives> (if you added it, C<contains>
always returns true) but a tunable rate of B<false positives> (it may
occasionally report an item as present that was never added). It never stores
the items themselves, only a bit array, so memory is proportional to the
configured capacity and false-positive rate, not to the size of the items.

Each item is hashed once with XXH3 (128-bit); the two 64-bit halves drive C<k>
probe positions into a power-of-two bit array via Kirsch-Mitzenmacher double
hashing. C<add> sets those C<k> bits; C<contains> reports present only if all
C<k> are set. The number of hashes C<k> and the bit-array size are derived from
the C<capacity> and C<fp_rate> you request.

Because the bit array lives in a shared mapping, B<several processes share one
filter>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd, sees the others' additions
and contributes its own. A write-preferring futex rwlock with dead-process
recovery guards mutation, so many processes may C<add> and C<contains>
concurrently. Two filters of identical geometry can be combined with C<merge>
(bitwise OR), which yields a filter whose membership is the B<union> of the two
input sets.

Items are added and tested by their B<byte> content; wide-character strings
(any codepoint above 255) cause a "Wide character" croak -- encode such strings
to bytes first (for example with C<Encode::encode_utf8>). B<Linux-only>.
Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $bf = Data::BloomFilter::Shared->new($path, $capacity, $fp_rate);
    my $bf = Data::BloomFilter::Shared->new(undef, 1_000_000);          # fp_rate 0.01
    my $bf = Data::BloomFilter::Shared->new_memfd($name, $capacity, $fp_rate);
    my $bf = Data::BloomFilter::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$capacity> is the number of items you expect to add; it must be at least 1.
C<$fp_rate> is the target false-positive rate at that capacity; it is optional,
defaults to B<0.01> (1%), and must be strictly between 0 and 1. C<new> and
C<new_memfd> croak if C<$capacity> is less than 1 or C<$fp_rate> is out of range.

From C<$capacity> and C<$fp_rate> the filter derives its geometry:
C<k = round(-log2(fp_rate))> hashes (clamped to the range 1..32), and a bit
array of C<m = next_power_of_two(ceil(capacity * k / ln 2))> bits (with a floor
of 64 bits). Rounding the bit count up to a power of two means the realised
false-positive rate at capacity is typically B<at or below> the configured
target. When reopening an existing file or memfd, the stored geometry wins and
the caller's C<$capacity>/C<$fp_rate> arguments are ignored. C<new_memfd>
creates a Linux memfd (transferable via its C<memfd> descriptor);
C<new_from_fd> reopens one in another process.

=head2 Adding and testing

    my $new   = $bf->add($item);            # 1 if probably new, else 0
    my $added = $bf->add_many(\@items);     # count of items that were probably new
    my $in    = $bf->contains($item);       # 1 if probably present, 0 if definitely absent
    $bf->clear;                             # reset to empty (all bits 0)

C<add> hashes C<$item> (taken by its bytes; wide characters croak, encode first)
and sets its C<k> bits, returning B<1 if the item was probably new> -- that is,
if at least one of its bits was previously unset -- and B<0> if all C<k> bits
were already set (the item was probably added before). A return of 0 is
therefore a "probably seen this already" signal, subject to the same
false-positive rate as C<contains>. C<add_many> takes an array reference and
does the whole batch under a single write lock, returning how many of its
elements were probably new.

C<contains> returns B<1 if the item is probably present> and B<0 if it is
definitely absent>. The contract is asymmetric and is the whole point of a Bloom
filter: a 0 is exact (the item was never added), while a 1 may be a B<false
positive> (some other items happened to set all of this item's bits). There are
B<never false negatives>: any item you have added always reports as present.

=head2 Merging

    $bf->merge($other);

Folds C<$other>'s bit array into C<$bf> by bitwise OR, so C<$bf> then reports as
present the B<union> of the two filters' item sets (still with no false
negatives). Both filters must have identical geometry -- the same number of bits
and the same number of hashes, which follows from constructing both with the
same C<$capacity> and C<$fp_rate> (C<merge> croaks on a mismatch). C<$other> is
read under its own lock into a private snapshot first, so merging is
deadlock-free even if two processes merge each other concurrently; C<$other> is
not modified.

=head2 Introspection and lifecycle

    $bf->capacity; $bf->bits; $bf->hashes; $bf->fp_rate; $bf->count; $bf->stats;
    $bf->path; $bf->memfd; $bf->sync; $bf->unlink;   # or Class->unlink($path)

C<capacity> is the configured item capacity; C<bits> is the bit-array size in
bits (a power of two); C<hashes> is the number of hash probes C<k>; C<fp_rate>
is the configured target false-positive rate. C<count> returns an estimate of
the number of distinct items added, computed from the fraction of bits set
(accurate while the filter is not saturated, and capped at C<capacity> once it
is). C<sync> flushes the mapping to its backing store (a no-op for anonymous and
memfd filters, which have none); C<unlink> removes the backing file (also
callable as C<< Class->unlink($path) >>); C<path> returns the backing path
(C<undef> for anonymous, memfd, or fd-reopened filters) and C<memfd> the backing
descriptor -- the memfd of a C<new_memfd> filter or the dup'd fd of a
C<new_from_fd> filter, and -1 for file-backed or anonymous filters.

=head1 STATS

C<stats()> returns a hashref describing the filter:

=over 4

=item * C<capacity> -- the configured item capacity.

=item * C<fp_rate> -- the configured target false-positive rate.

=item * C<bits> -- the bit-array size in bits (a power of two).

=item * C<hashes> -- the number of hash probes C<k> per item.

=item * C<bits_set> -- how many bits are currently set.

=item * C<count> -- the estimated number of distinct items added.

=item * C<fill_ratio> -- C<bits_set / bits>, between 0 and 1. As this approaches
0.5 the filter is near its designed capacity and the realised false-positive
rate approaches the configured target; well above that the rate climbs.

=item * C<ops> -- running count of mutating operations (C<add>, C<add_many>,
C<merge>, C<clear>).

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The filter lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, ...) >> on the
same path with matching capacity and rate), an B<anonymous mapping inherited
across C<fork>>, or a B<memfd> whose descriptor is passed to an unrelated
process (over a UNIX socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and
reopened with C<< new_from_fd($fd) >>. Because the mapping is shared, B<every
process adds into and tests against the same bit array>, so membership reflects
the union of what all of them have added.

    # producer and consumer share one filter with no coordination
    my $bf = Data::BloomFilter::Shared->new(undef, 100_000, 0.01);   # before fork
    unless (fork) { $bf->add_many([ map { "ev-$_" } 1 .. 1000 ]); exit }
    wait;
    print $bf->contains("ev-500") ? "seen\n" : "no\n";   # seen -- the child's add

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
recovers. Each bit set is a single word store, so a crash leaves the filter
consistent up to the last completed C<add>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::HyperLogLog::Shared>, L<Data::Intern::Shared>,
L<Data::SortedSet::Shared>, L<Data::SpatialHash::Shared>, and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
