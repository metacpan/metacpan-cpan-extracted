package Data::Reservoir::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::Reservoir::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::Reservoir::Shared - shared-memory reservoir sampler (uniform stream sample)

=head1 SYNOPSIS

    use Data::Reservoir::Shared;

    # keep a uniform random sample of 100 items from an unbounded stream
    my $rsv = Data::Reservoir::Shared->new(undef, 100);

    $rsv->add($_) for @stream;      # feed items; each is kept or discarded

    my @sample = $rsv->sample;      # up to 100 items, uniformly sampled
    $rsv->count;                    # how many are held (min of seen, 100)
    $rsv->seen;                     # total items observed

    # share the reservoir across processes via a backing file
    my $shared = Data::Reservoir::Shared->new("/tmp/sample.rsv", 100);

    # weighted sampling: keep items with probability proportional to weight
    my $wrsv = Data::Reservoir::Shared->new_weighted(undef, 100);
    $wrsv->add($event, $weight) for @stream;   # heavier items kept more often

=head1 DESCRIPTION

A B<reservoir sampler> in shared memory: it keeps a B<uniform random sample of
C<k> items> drawn from a stream of unknown or unbounded length, in fixed memory,
using B<Algorithm R>. Feed it items one at a time with C<add>; while fewer than
C<k> items have been seen every item is kept, and after that the i-th item
replaces a uniformly random slot with probability C<k/i>. At any point the C<k>
retained items are a uniform random sample of everything seen so far -- the
standard way to sample a log stream, sample events for telemetry, or take a fair
sample of a data set too large to hold.

Because the reservoir lives in a shared mapping, B<several processes feed and
read one sample>: any process that opens the same backing file, inherits the
anonymous mapping across C<fork>, or reopens a passed memfd contributes to and
reads the same reservoir. The sampling RNG (a xorshift64) lives in the shared
header and is advanced under the write lock, so concurrent producers sample one
consistent reservoir. A write-preferring futex rwlock with dead-process recovery
guards mutation.

Items are stored B<inline>, truncated to C<item_size> bytes (default 256): an
item longer than C<item_size> keeps only its first C<item_size> bytes. Memory is
about C<k * S> bytes for the slots, where the per-slot stride C<S> rounds
C<8 + item_size> up to a multiple of 8, plus a fixed header. Items are handled
by their B<byte> content; wide-character strings (any codepoint above 255) cause
a "Wide character" croak -- encode to bytes first. B<Linux-only>. Requires 64-bit
Perl.

=head2 Weighted sampling (A-Res)

A reservoir created with C<new_weighted> keeps a B<weighted> random sample: each
item carries a positive weight and is retained with probability proportional to
its weight rather than uniformly. This is the B<Efraimidis-Spirakis A-Res>
algorithm -- each observed item is assigned a key C<u ** (1/weight)> (with C<u>
uniform in C<(0,1]>) and the C<k> items with the largest keys are kept, tracked
in a shared min-heap so a heavier arrival can evict the current lightest member.
With a single slot the probability of keeping item C<i> is exactly
C<< w_i / sum(w) >>. Feed weighted items with C<< $rsv->add($item, $weight) >> (the
weight must be a finite number greater than zero); everything else -- C<sample>,
C<count>, C<get>, C<clear>, and cross-process sharing -- works identically. A
weighted reservoir stores an extra C<k * 16> bytes for the heap and records its
mode in the header, so a reopened segment stays weighted.

=head1 METHODS

=head2 Constructors

    my $rsv = Data::Reservoir::Shared->new($path, $k, $item_size);
    my $rsv = Data::Reservoir::Shared->new(undef, $k);              # anonymous, item_size 256
    my $rsv = Data::Reservoir::Shared->new_memfd($name, $k, $item_size);
    my $rsv = Data::Reservoir::Shared->new_from_fd($fd);

    # weighted (A-Res) reservoir -- same arguments, weighted sampling
    my $rsv = Data::Reservoir::Shared->new_weighted($path, $k, $item_size);
    my $rsv = Data::Reservoir::Shared->new_weighted_memfd($name, $k, $item_size);

C<$k> is the reservoir size (the number of items to retain, at least 1).
C<$item_size> is the maximum bytes stored per item (default 256; items are
truncated to it). C<new> and C<new_memfd> croak on a size below 1 or an
out-of-range C<$item_size>. When reopening an existing file or memfd the stored
geometry wins and the caller's arguments are ignored. An optional file B<mode>
may be passed as the last argument to C<new> (e.g. C<0660>) for cross-user
sharing; it defaults to C<0600> (owner-only).

=head2 Sampling

    my $kept  = $rsv->add($item);            # uniform: 1 if now stored, 0 if discarded
    my $kept  = $rsv->add($item, $weight);    # weighted reservoir: weight must be > 0
    my $n     = $rsv->add_many(\@items);              # uniform: array ref of items
    my $n     = $rsv->add_many([[$item,$w], ...]);     # weighted: [item, weight] pairs
    my @items = $rsv->sample;            # current sample (a list, up to k items)
    my $it    = $rsv->get($i);           # the i-th retained item (0-based), or undef
    $rsv->clear;                         # empty the reservoir (seen resets to 0)

C<add> feeds one item and returns B<1 if it is now stored> in the reservoir or
B<0 if it was discarded>. On a B<weighted> reservoir C<add> takes a second
argument, the item's weight (a finite number greater than zero -- a missing,
zero, negative, infinite, or NaN weight croaks). C<add_many> feeds an array
reference under a single write lock, returning how many of the batch were
stored (an item that replaces an earlier sample counts as stored; use
C<count> for the number currently retained); for a weighted reservoir each
element must be an C<< [$item, $weight] >> pair. C<sample> returns the retained items as a list
(order is not meaningful); C<get> returns a single retained item by index.
C<clear> empties the reservoir and resets the seen counter.

=head2 Introspection and RNG

    $rsv->count;        # number of items currently held: min(seen, k)
    $rsv->seen;         # total items observed
    $rsv->capacity;     # k
    $rsv->item_size;    # max bytes per item
    $rsv->is_weighted;  # true for a weighted (A-Res) reservoir
    $rsv->seed($n);     # set the RNG state (for reproducible sampling in tests)
    $rsv->stats;        # { size, item_size, count, seen, ops, mmap_size, weighted }

C<seed> sets the shared RNG state to a fixed value, making subsequent sampling
deterministic -- useful for reproducible tests. By default the RNG is seeded from
process and clock entropy at creation, so different runs draw different samples.

=head2 Lifecycle

    $rsv->path; $rsv->memfd; $rsv->sync; $rsv->unlink;

C<sync> flushes the mapping to its backing store (a no-op for anonymous and memfd
reservoirs); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened reservoirs) and C<memfd> the backing descriptor.

=head1 SHARING ACROSS PROCESSES

The reservoir lives in a shared mapping, shared the same three ways as the rest
of the family: a B<backing file>, an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Every process's C<add> feeds the one shared reservoir,
and the shared RNG keeps the sampling probabilities consistent across producers.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Each C<add> is a short bounded update, so a
crash leaves the reservoir consistent up to the last completed operation.
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

L<Data::HyperLogLog::Shared> (cardinality estimation), L<Data::CountMinSketch::Shared>
(frequency estimation), and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
