package Data::DDSketch::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::DDSketch::Shared', $VERSION);

*insert = \&add;                 # zero-overhead alias (same CV via typeglob)
sub median { $_[0]->quantile(0.5) }

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::DDSketch::Shared - shared-memory DDSketch relative-error quantile sketch

=head1 SYNOPSIS

    use Data::DDSketch::Shared;

    # 1% relative-error quantiles
    my $dd = Data::DDSketch::Shared->new(undef, 0.01);

    $dd->add($_) for @latencies;    # feed values (e.g. request latencies)

    my $p50 = $dd->quantile(0.50);  # median, within 1% of the true value
    my $p99 = $dd->quantile(0.99);  # tail latency
    my $max = $dd->max;             # exact min/max are tracked too

    # share the sketch across processes via a backing file
    my $shared = Data::DDSketch::Shared->new("/tmp/latency.dd", 0.01);

=head1 DESCRIPTION

A B<DDSketch> in shared memory: it estimates any B<quantile> of a stream of
numbers to within a configured B<relative accuracy> C<alpha> (default 1%), in a
fixed amount of memory, no matter how many values are added. Unlike a fixed
histogram, the guarantee is B<relative>: the returned value for any quantile is
within a factor C<alpha> of the true value, whether that quantile is a
microsecond or an hour -- which is what you want for latencies and other
long-tailed, wide-dynamic-range data.

Each value C<v> falls into a logarithmic bucket keyed by
C<ceil(log_gamma(|v|))>, with C<gamma = (1 + alpha) / (1 - alpha)>; every value
in a bucket is within C<alpha> of the bucket's representative value. Positive and
negative magnitudes use separate bucket stores and exact zeros a dedicated
counter, so the full real line is covered. The sketch also tracks the exact
count, minimum, and maximum, plus a running sum, giving mean and true extremes
for free.

Because the buckets live in a shared mapping, B<several processes feed one
sketch>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd contributes to and reads the
same distribution. A write-preferring futex rwlock with dead-process recovery
guards mutation. B<Linux-only>. Requires 64-bit Perl.

Memory is bounded at C<num_buckets> counters per sign (default 2048): the buckets
form a fixed window centred on value 1, and values whose magnitude falls outside
the window collapse into the nearest extreme bucket. With the defaults the window
spans roughly C<1.5e-9> to C<6.6e8>, so ordinary data never reaches the edges;
raise C<num_buckets> for a wider exact range. Two sketches created with the same
C<alpha> and C<num_buckets> can be merged.

=head1 METHODS

=head2 Constructors

    my $dd = Data::DDSketch::Shared->new($path, $alpha, $num_buckets, $mode);
    my $dd = Data::DDSketch::Shared->new(undef, 0.01);            # anonymous, 2048 buckets
    my $dd = Data::DDSketch::Shared->new_memfd($name, $alpha, $num_buckets);
    my $dd = Data::DDSketch::Shared->new_from_fd($fd);

C<$alpha> is the relative accuracy (default 0.01 = 1%; between 1e-6 and 0.5).
C<$num_buckets> is the number of counters per sign (default 2048; between 8 and
2^24) and sets both the memory use (C<2 * num_buckets * 8> bytes plus a fixed
header) and the exact value range. C<new> and C<new_memfd> croak on an
out-of-range C<$alpha> or C<$num_buckets>. When reopening an existing file or
memfd the stored geometry wins and the caller's arguments are ignored. An
optional file B<mode> may be passed as the last argument to C<new> (e.g. C<0660>)
for cross-user sharing; it defaults to C<0600> (owner-only).

=head2 Feeding values

    my $n = $dd->add($value);        # add one value; returns the new total count
    $dd->insert($value);             # alias for add
    $dd->add_many(\@values);         # add a batch under a single write lock
    $dd->clear;                      # empty the sketch

C<add> adds one finite number (croaks on C<NaN> or infinity) and returns the
running total count. C<add_many> adds an array reference of numbers under one
write lock, validating them all first. Negative values and zero are supported.

=head2 Querying

    my $v   = $dd->quantile($q);     # value at quantile $q in 0 .. 1 (undef if empty)
    my $med = $dd->median;           # quantile(0.5)
    $dd->min; $dd->max;              # exact smallest / largest value (undef if empty)
    $dd->mean;                       # running mean (undef if empty)
    $dd->sum; $dd->count;            # running sum and exact number of values
    $dd->zero_count;                 # how many exact-zero values were added

C<quantile> returns the estimated value at quantile C<$q> (e.g. C<0.99> for the
99th percentile), guaranteed within relative error C<alpha> of the true value; it
returns C<undef> for an empty sketch and croaks if C<$q> is outside C<[0, 1]>.
C<min>, C<max>, and C<count> are B<exact> (tracked separately from the
buckets); C<sum> and C<mean> are double-precision running values subject to
floating-point rounding.

=head2 Merging and introspection

    $dd->merge($other);              # fold another sketch's values in (same alpha + num_buckets)
    $dd->alpha; $dd->gamma; $dd->num_buckets;
    $dd->stats;   # { alpha, gamma, num_buckets, count, zero_count, sum, min, max, mean, ops, mmap_size }

C<merge> requires C<$other> to have the same C<alpha> and C<num_buckets> and
croaks otherwise; afterwards this sketch represents the combined distribution.

=head2 Lifecycle

    $dd->path; $dd->memfd; $dd->sync; $dd->unlink;

C<sync> flushes the mapping to its backing store (a no-op for anonymous and memfd
sketches); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened sketches) and C<memfd> the backing descriptor.

=head1 ACCURACY

For any quantile, the returned value C<e> and the true value C<v> satisfy
C<|e - v| <= alpha * |v|> -- a relative guarantee that holds across the whole
range, so the 99.9th percentile of a heavy tail is as accurate (in relative
terms) as the median. This is the property a fixed-bucket histogram lacks. The
count, minimum, and maximum are exact; the sum and mean are double-precision
running values subject to floating-point rounding. The only approximation is
the per-quantile value, and only for magnitudes inside the representable window;
magnitudes outside it collapse into the extreme bucket and lose accuracy.

=head1 SHARING ACROSS PROCESSES

The sketch lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Every process's C<add> feeds the one shared sketch, so a
fleet of workers can each measure part of a workload into a single distribution.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Each C<add> is a short bounded update, but
recovery restores locking only -- it performs no state repair. C<add> commits
the scalar aggregates (count, sum, min, max) before the bucket counter, so a
crash in that window leaves C<count> ahead of the buckets and
C<quantile(1.0)> can return C<undef> on a non-empty sketch until the next
C<add> completes.
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

L<Data::Histogram::Shared> (fixed-bucket histogram), the DDSketch paper (Masson,
Rim, Lee, 2019), and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
