package Data::Histogram::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::Histogram::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

*percentile = \&value_at_percentile;
*count      = \&total_count;

1;
__END__

=encoding utf-8

=head1 NAME

Data::Histogram::Shared - shared-memory HdrHistogram for Linux

=head1 SYNOPSIS

    use Data::Histogram::Shared;

    # track values in [1, 3_600_000_000] with 3 significant figures, anonymous
    my $h = Data::Histogram::Shared->new(undef, 1, 3_600_000_000, 3);

    $h->record(120);              # record the value 120 once
    $h->record(2500, 4);          # record the value 2500 four times

    $h->value_at_percentile(50);  # median (50th percentile)
    $h->percentile(99);           # 99th percentile (alias)
    $h->min; $h->max; $h->mean;   # min / max / arithmetic mean
    $h->total_count;              # number of recorded values

    # bulk record in a single lock acquisition
    $h->record_many([ 100, 250, 250, 900, 1500 ]);

    # merge another histogram of identical geometry (cellwise add)
    my $other = Data::Histogram::Shared->new(undef, 1, 3_600_000_000, 3);
    $other->record_many([ 50, 75, 80 ]);
    $h->merge($other);

    # share across processes via a backing file
    my $shared = Data::Histogram::Shared->new("/tmp/latency.hdr", 1, 3_600_000_000, 3);

=head1 DESCRIPTION

A High Dynamic Range histogram (HdrHistogram) in shared memory: a compact,
fixed-size structure that records B<integer> values across a very wide range and
answers percentile, minimum, maximum and mean queries within a fixed,
configurable relative error. It is the standard tool for latency and response-
time measurement, where the values of interest span many orders of magnitude
(microseconds to seconds) yet a constant number of significant figures must be
preserved across the whole range.

You construct the histogram with the C<lowest> and C<highest> values it must
track and the number of C<sig_figs> (significant figures) of precision you
require. Values are bucketed logarithmically -- one bucket per power of two of
magnitude -- and linearly within each bucket, so that any two values that agree
to C<sig_figs> significant figures fall into the same sub-bucket and are treated
as B<equivalent>. A percentile query is therefore accurate to within
C<1 / 10**sig_figs> relative error: with the default 3 significant figures, a
reported percentile is within 0.1% of the true value. Memory is proportional to
the dynamic range and the precision, B<not> to the number of values recorded:
you can record billions of samples into a few kilobytes of counters.

The histogram stores B<integer> values only. To record floating-point
quantities, scale them to integers yourself before recording -- for example,
record a latency in microseconds (or nanoseconds) rather than fractional
seconds, and divide the reported percentiles back down.

Because the counts array lives in a shared mapping, B<several processes share
one histogram>: any process that opens the same backing file, inherits the
anonymous mapping across C<fork>, or reopens a passed memfd, sees the others'
recordings and contributes its own. A write-preferring futex rwlock with
dead-process recovery guards mutation, so many processes may C<record> and query
concurrently. Two histograms of B<identical geometry> (same C<lowest>,
C<highest> and C<sig_figs>) can be combined with C<merge> (cellwise add of their
counts arrays), which yields a histogram whose distribution is the B<union> of
the two input streams. B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $h = Data::Histogram::Shared->new($path, $lowest, $highest, $sig_figs, $mode);
    my $h = Data::Histogram::Shared->new(undef, 1, 3_600_000_000, 3);   # defaults
    my $h = Data::Histogram::Shared->new_memfd($name, $lowest, $highest, $sig_figs);
    my $h = Data::Histogram::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$lowest> is the lowest value that can be distinguished from 0 and must be
C<E<gt>= 1> (default 1). C<$highest> is the highest value that can be tracked and
must be C<E<gt>= 2 * $lowest> (default C<3_600_000_000>, i.e. one hour in
microseconds). C<$sig_figs> is the number of significant figures of precision
and must be in the range 1..5 (default 3). C<new> and C<new_memfd> croak if any
argument is out of range.

C<$mode> sets the permission bits used when C<new> B<creates> the backing file
(still subject to the process umask); the default is C<0600>, owner-only. Pass
e.g. C<0660> to opt in to sharing the file with other users in the group. It
applies only at creation: reopening an existing file does not change its
permissions, and the argument is ignored for anonymous histograms (C<$path>
undef or omitted). C<new_memfd> and C<new_from_fd> do not take a mode.

C<$lowest> additionally must satisfy
C<floor(log2($lowest)) + ceil(log2(2 * 10**$sig_figs)) - 1 E<lt>= 61> (a
histogram-geometry limit); in practice this only rejects a very large
C<$lowest> -- above roughly C<2**51> at the default C<sig_figs = 3>. Such a
histogram croaks at construction.

From these the histogram derives its bucket geometry: a unit magnitude of
C<floor(log2($lowest))>, C<2 * 10**sig_figs> sub-buckets per power of two
(rounded up to a power of two), and as many buckets as are needed to cover
C<$highest>. When reopening an existing file or memfd, the B<stored geometry
wins> and the caller's C<$lowest>/C<$highest>/C<$sig_figs> arguments are
ignored. C<new_memfd> creates a Linux memfd (transferable via its
C<memfd> descriptor); C<new_from_fd> reopens one in another process.

=head2 Recording values

    my $count = $h->record($value);          # record once;  returns new total_count
    my $count = $h->record($value, $n);      # record $n times; returns new total_count
    my $added = $h->record_many(\@values);    # record each once; returns how many
    $h->reset;                               # clear every count back to empty

C<record> adds C<$n> (default 1) occurrences of the integer C<$value> to the
histogram and returns the new C<total_count>. C<$value> must be in the range
C<0 .. $highest>: a negative value croaks, and a value above C<$highest> croaks
(C<"value ... exceeds highest_trackable_value">). Values strictly below
C<$lowest> are recorded but collapse into the lowest sub-bucket. C<$n> is an
unsigned integer.

C<record_many> takes an array reference and records each element once under a
single write lock, returning the number recorded. Every element is range-checked
B<before> the lock is taken, so an out-of-range element croaks without recording
any of the batch (and without holding the lock).

The B<precision contract>: any two values that agree to C<sig_figs> significant
figures are B<equivalent> -- they fall into the same sub-bucket and are
indistinguishable once recorded. A value read back out of the histogram (for
example via a percentile query) is the B<highest> value equivalent to the bucket
it landed in, so it is always C<E<gt>= > the recorded value and within
C<1 / 10**sig_figs> relative error of it.

=head2 Querying

    my $v = $h->value_at_percentile($p);     # value at the $p-th percentile (0..100)
    my $v = $h->percentile($p);              # alias for value_at_percentile
    my $c = $h->count_at_value($value);      # count recorded in $value's bucket
    my $lo = $h->min;                        # lowest recorded value (0 if empty)
    my $hi = $h->max;                        # highest recorded value (0 if empty)
    my $mu = $h->mean;                       # arithmetic mean (0 if empty)
    my $n  = $h->total_count;                # number of recorded values
    my $n  = $h->count;                      # alias for total_count

C<value_at_percentile> returns the value below which C<$p> percent of the
recorded values lie: the B<highest equivalent value> of the bucket at that
percentile, so it never underestimates. C<$p> is a percentile in the range
0..100 (not a 0..1 quantile). C<percentile> is a short alias. An empty histogram
returns 0 for any percentile.

C<count_at_value> returns the number of values recorded in the bucket that
C<$value> falls into (so values equivalent to C<$value> are counted together).
C<$value> is range-checked like C<record>: a negative value, or a value above
C<$highest>, croaks.
C<min> and C<max> are the exact lowest and highest values ever recorded (each 0
when nothing has been recorded). C<mean> is the arithmetic mean, computed from
each bucket's median-equivalent value. C<total_count> (aliased C<count>) is the
number of recorded values -- the sum of all the per-bucket counts.

=head2 Merging

    $h->merge($other);

Folds C<$other>'s counts array into C<$h> by cellwise addition, so C<$h> then
represents the combined distribution of both histograms; C<$h>'s C<total_count>,
C<min> and C<max> are updated to span both. Both histograms must have B<identical
geometry> -- the same C<lowest>, C<highest> and C<sig_figs> (C<merge> croaks on a
mismatch). C<$other> is read under its own lock into a private snapshot first, so
merging is deadlock-free even if two processes merge each other concurrently;
C<$other> is not modified. Counts that would overflow a 64-bit cell saturate at
the maximum value.

=head2 Introspection and lifecycle

    $h->lowest; $h->highest; $h->sig_figs; $h->counts_len; $h->stats;
    $h->path; $h->memfd; $h->sync; $h->unlink;   # or Class->unlink($path)

C<lowest>, C<highest> and C<sig_figs> return the configured geometry;
C<counts_len> is the number of 64-bit counter cells. C<sync> flushes the mapping
to its backing store (a no-op for anonymous and memfd histograms, which have
none); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened histograms) and C<memfd> the backing descriptor
-- the memfd of a C<new_memfd> histogram or the dup'd fd of a C<new_from_fd>
histogram, and -1 for file-backed or anonymous histograms.

=head1 STATS

C<stats()> returns a hashref describing the histogram:

=over 4

=item * C<lowest> -- the lowest trackable value.

=item * C<highest> -- the highest trackable value.

=item * C<sig_figs> -- the significant figures of precision.

=item * C<count> -- the number of recorded values (C<total_count>).

=item * C<min> -- the lowest recorded value (0 if empty).

=item * C<max> -- the highest recorded value (0 if empty).

=item * C<mean> -- the arithmetic mean of the recorded values (0.0 if empty).

=item * C<counts_len> -- the number of 64-bit counter cells.

=item * C<bucket_count> -- the number of logarithmic buckets.

=item * C<sub_bucket_count> -- the number of linear sub-buckets per bucket.

=item * C<ops> -- running count of mutating operations (C<record>,
C<record_many>, C<merge>, C<reset>).

=item * C<mmap_size> -- bytes of the shared mapping.

=back

=head1 SHARING ACROSS PROCESSES

The histogram lives in a shared mapping, shared the same three ways as the rest
of the family: a B<backing file> (every process calls C<< new($path, ...) >> on
the same path with matching geometry), an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> whose descriptor is passed to an unrelated process (over
a UNIX socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process records
into and queries the same counts array>, so the distribution reflects the
combined stream all of them have recorded.

    # producer and consumer share one histogram with no coordination
    my $h = Data::Histogram::Shared->new(undef, 1, 1_000_000, 3);   # before fork
    unless (fork) { $h->record(500) for 1 .. 10; exit }
    wait;
    print $h->value_at_percentile(50), "\n";   # the child's recordings

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
recovers. Each count increment is a single word store, so a crash leaves the
histogram consistent up to the last completed C<record>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::CountMinSketch::Shared>, L<Data::HyperLogLog::Shared>,
L<Data::BloomFilter::Shared>, L<Data::Intern::Shared>,
L<Data::SortedSet::Shared>, L<Data::SpatialHash::Shared>, and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
