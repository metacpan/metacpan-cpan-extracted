package Data::HyperLogLog::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::HyperLogLog::Shared', $VERSION);
1;
__END__

=encoding utf-8

=head1 NAME

Data::HyperLogLog::Shared - shared-memory HyperLogLog cardinality estimator for Linux

=head1 SYNOPSIS

    use Data::HyperLogLog::Shared;

    # default precision 14 (16384 registers, ~0.8% std error), anonymous mapping
    my $hll = Data::HyperLogLog::Shared->new;

    $hll->add("alice");
    $hll->add("bob");
    $hll->add("alice");                 # already seen: no register increases

    my $n = $hll->count;                # ~2 (estimated distinct items)

    # bulk add in a single lock acquisition
    my $new = $hll->add_many([ map { "user-$_" } 1 .. 1000 ]);

    # merge another estimator of equal precision (register-wise max)
    my $other = Data::HyperLogLog::Shared->new;
    $other->add_many([ map { "user-$_" } 500 .. 1500 ]);
    $hll->merge($other);
    my $union = $hll->count;            # ~1500 distinct across both

    # share across processes via a backing file
    my $shared = Data::HyperLogLog::Shared->new("/tmp/visitors.hll", 14);

=head1 DESCRIPTION

A HyperLogLog estimator in shared memory: it counts the number of B<distinct>
items it has seen (a probabilistic distinct-count) in a fixed, tiny amount of
memory, regardless of how many items pass through it. It never stores the items;
it keeps only an array of C<m = 2**precision> single-byte registers (16 KB at the
default precision 14) plus a fixed ~16 KB region for the cross-process reader
table, so the whole mapping is about 32 KB at precision 14 (see C<mmap_size> in
L</STATS>). It yields a relative standard error of roughly B<0.8%>.

Each item is hashed with XXH3; the top C<precision> bits of the hash select a
register, and the position of the first set bit in the remaining bits is folded
into that register as a running maximum. The harmonic mean of the registers,
with a small-range linear-counting correction, gives the estimate.

Because the register array lives in a shared mapping, B<several processes share
one estimator>: any process that opens the same backing file, inherits the
anonymous mapping across C<fork>, or reopens a passed memfd, sees the others'
additions and contributes its own. A write-preferring futex rwlock with
dead-process recovery guards mutation, so many processes may C<add> and C<count>
concurrently. Two estimators of equal precision can be combined with C<merge>
(register-wise max), which gives the cardinality of the B<union> of their item
sets without double-counting overlaps.

Items are added by their B<byte> content (encode wide/utf8 strings first).
B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $hll = Data::HyperLogLog::Shared->new($path, $precision);
    my $hll = Data::HyperLogLog::Shared->new;                       # anonymous, precision 14
    my $hll = Data::HyperLogLog::Shared->new(undef, 16);            # anonymous, precision 16
    my $hll = Data::HyperLogLog::Shared->new_memfd($name, $precision);
    my $hll = Data::HyperLogLog::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$precision> is optional and defaults to B<14>; it must be between B<4> and
B<18> (C<new> croaks otherwise). The register count is C<m = 2**precision>
(precision 4 -> 16 registers, 18 -> 262144), and the relative standard error is
about C<1.04 / sqrt(m)> (precision 14 -> ~0.81%, 16 -> ~0.41%, 12 -> ~1.63%).
When reopening an existing file or memfd, the stored precision wins and the
caller's argument is ignored. C<new_memfd> creates a Linux memfd (transferable
via its C<memfd> descriptor); C<new_from_fd> reopens one in another process.

=head2 Adding and counting

    my $bumped = $hll->add($item);          # 1 if a register increased, else 0
    my $added  = $hll->add_many(\@items);   # count of items that increased a register
    my $n      = $hll->count;               # estimated distinct items (rounded)
    $hll->clear;                            # reset to empty (count -> 0)

C<add> hashes C<$item> (taken by its bytes; wide characters croak, encode first)
and updates the relevant register, returning 1 if that register increased and 0
otherwise. A return of 0 does B<not> mean the item was seen before -- it means
its hash did not beat the current register value; treat the return only as "did
this change the sketch". C<add_many> takes an array reference and does the whole
batch under a single write lock, returning how many of its elements increased a
register. C<count> returns the current estimate rounded to the nearest integer.

=head2 Merging

    $hll->merge($other);

Folds C<$other>'s registers into C<$hll> by register-wise maximum, so C<$hll>
then estimates the cardinality of the B<union> of the two item sets. Both
estimators must have the same precision (C<merge> croaks on a mismatch).
C<$other> is read under its own lock into a private snapshot first, so merging
is deadlock-free even if two processes merge each other concurrently; C<$other>
is not modified.

=head2 Introspection and lifecycle

    $hll->precision; $hll->registers; $hll->count; $hll->stats;
    $hll->path; $hll->memfd; $hll->sync; $hll->unlink;   # or Class->unlink($path)

C<precision> is the configured precision; C<registers> is the register count
C<m> (C<2**precision>). C<sync> flushes the mapping to its backing store (a
no-op for anonymous and memfd estimators, which have none); C<unlink> removes
the backing file (also callable as C<< Class->unlink($path) >>); C<path> returns
the backing path (C<undef> for anonymous, memfd, or fd-reopened estimators) and
C<memfd> the backing descriptor -- the memfd of a C<new_memfd> estimator or the
dup'd fd of a C<new_from_fd> estimator, and -1 for file-backed or anonymous
estimators.

=head1 STATS

C<stats()> returns a hashref: C<precision>, C<registers> (the register count
C<m>), C<count> (the current rounded estimate), C<ops> (running count of
mutating operations -- C<add>, C<add_many>, C<merge>, C<clear>), and
C<mmap_size> (bytes of the shared mapping).

=head1 ACCURACY

The relative standard error is approximately C<1.04 / sqrt(m)> where
C<m = 2**precision>. At the default precision 14 that is about 0.8%; roughly two
thirds of estimates fall within one standard error of the truth and almost all
within three. For very small cardinalities (when the estimate is at or below
C<2.5 * m> and some registers are still zero) the estimator switches to linear
counting, which is accurate in that range. There is no large-range (2^32)
correction: with 64-bit hashes the hash space is effectively collision-free for
any cardinality this is used for.

=head1 SHARING ACROSS PROCESSES

The estimator lives in a shared mapping, shared the same three ways as the rest
of the family: a B<backing file> (every process calls C<< new($path, ...) >> on
the same path), an B<anonymous mapping inherited across C<fork>>, or a B<memfd>
whose descriptor is passed to an unrelated process (over a UNIX socket via
C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and reopened with
C<< new_from_fd($fd) >>. Because the mapping is shared, B<every process adds into
and reads from the same set of registers>, so the cardinality reflects the union
of what all of them have seen.

    # producer and consumer share one estimator with no coordination
    my $hll = Data::HyperLogLog::Shared->new;            # before fork
    unless (fork) { $hll->add_many([ map { "ev-$_" } 1 .. 1000 ]); exit }
    wait;
    print $hll->count, "\n";   # ~1000, counting the child's additions

=head1 SECURITY

The mmap region is writable by all processes that open it. Do not share backing
files with untrusted processes.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Each register update is a single byte store, so a crash leaves the
estimator consistent up to the last completed C<add>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

=head1 SEE ALSO

L<Data::Intern::Shared>, L<Data::SortedSet::Shared>,
L<Data::SpatialHash::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
