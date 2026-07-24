package Data::MinHash::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::MinHash::Shared', $VERSION);

*jaccard  = \&similarity;   # zero-overhead aliases (same CV via typeglob)
*capacity = \&size;

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::MinHash::Shared - shared-memory MinHash sketch (Jaccard similarity estimation, b-bit signatures)

=head1 SYNOPSIS

    use Data::MinHash::Shared;

    # two sketches with the same number of registers
    my $a = Data::MinHash::Shared->new(undef, 256);
    my $b = Data::MinHash::Shared->new(undef, 256);

    $a->add($_) for @set_a;         # fold each set's elements in
    $b->add($_) for @set_b;

    my $j = $a->similarity($b);     # estimated Jaccard similarity, 0 .. 1

    $a->merge($b);                  # $a becomes the sketch of A union B

    # share a sketch across processes via a backing file
    my $shared = Data::MinHash::Shared->new("/tmp/set.mh", 256);

    # b-bit MinHash: estimate from only the low b bits, and export a compact signature
    my $j     = $a->bbit_similarity($b, 1);    # corrected estimate from 1 bit per register
    my $sig_a = $a->bbit_signature(1);         # 256 bits = 32 bytes (vs 2 KiB full sketch)
    my $sig_b = $b->bbit_signature(1);
    my $j2    = Data::MinHash::Shared->bbit_similarity_of($sig_a, $sig_b, 256, 1);

=head1 DESCRIPTION

A B<MinHash sketch> in shared memory: it summarises a set as C<k> "minimum hash"
registers so that the B<Jaccard similarity> of two sets -- the size of their
intersection over the size of their union -- can be estimated from the fraction
of registers that agree between their two sketches, in a fixed amount of memory
independent of how many elements were added.

Each element is hashed once (XXH3-64) and mixed with each register's index, so
the C<k> registers behave like C<k> independent min-hashes; every register keeps
the smallest value it has ever seen. Two sets that share many elements keep the
same minima in many registers, so C<agreeing_registers / k> is an unbiased
estimate of their Jaccard similarity. Accuracy improves with C<k>: the standard
error of the estimate is about C<1/sqrt(k)> (e.g. C<k = 256> gives roughly a
6% standard error, C<k = 1024> about 3%).

Because the sketch lives in a shared mapping, B<several processes update and read
one sketch>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd folds into and reads the same
registers. A write-preferring futex rwlock with dead-process recovery guards
mutation. Elements are handled by their B<byte> content; wide-character strings
(any codepoint above 255) cause a "Wide character" croak -- encode to bytes
first. B<Linux-only>. Requires 64-bit Perl.

Two sketches must have B<the same number of registers> to be compared or merged;
C<similarity> and C<merge> croak on a register-count mismatch.

=head2 b-bit MinHash

B<b-bit MinHash> (Li and Koenig) compares only the B<low C<b> bits> of each
register instead of the full 64. Two registers whose true minima differ still
collide in C<b> bits with probability C<2**-b>, so the observed match fraction
C<f> is corrected to a Jaccard estimate as C<< (f - 2**-b) / (1 - 2**-b) >>.
Small C<b> (even C<b == 1>) gives a good estimate for all but very high
similarities, at a fraction of the storage: a C<b>-bit B<signature> is
C<ceil(k * b / 8)> bytes -- e.g. C<64x> smaller than the full sketch at C<b == 1>
-- which makes it cheap to store or ship many finalized sketches.

Because this sketch is B<incremental> (each register keeps a running 64-bit
minimum, which the low bits alone cannot maintain), b-bit is offered as a
B<finalization>: the live sketch stays full, and you either compare two live
sketches with C<bbit_similarity>, or C<bbit_signature> a snapshot for compact
storage and later compare snapshots with C<bbit_similarity_of>. C<b> ranges from
1 to 64 (C<b == 64> is exactly the full C<similarity>).

=head1 METHODS

=head2 Constructors

    my $mh = Data::MinHash::Shared->new($path, $k, $mode);
    my $mh = Data::MinHash::Shared->new(undef, $k);              # anonymous
    my $mh = Data::MinHash::Shared->new_memfd($name, $k);
    my $mh = Data::MinHash::Shared->new_from_fd($fd);

C<$k> is the number of registers (at least 1, up to 2^24) and sets the
accuracy/memory trade-off; memory is C<k * 8> bytes for the registers plus a
fixed header. C<new> and C<new_memfd> croak on a C<$k> below 1 or above 2^24.
When reopening an existing file or memfd the stored C<$k> wins and the caller's
argument is ignored. An optional file B<mode> may be passed as the last argument
to C<new> (e.g. C<0660>) for cross-user sharing; it defaults to C<0600>
(owner-only).

=head2 Building and comparing

    my $changed = $mh->add($element);       # 1 if a register was lowered, else 0
    my $n       = $mh->add_many(\@elements); # how many adds lowered a register
    my $j       = $mh->similarity($other);   # estimated Jaccard similarity (0 .. 1)
    my $j       = $mh->jaccard($other);      # alias for similarity
    $mh->merge($other);                      # this sketch becomes the union's sketch
    $mh->clear;                              # reset to the empty sketch

    # b-bit MinHash (see above)
    my $j   = $mh->bbit_similarity($other, $b);   # Jaccard from the low $b bits (b: 1..64)
    my $sig = $mh->bbit_signature($b);            # compact packed signature, ceil(k*b/8) bytes
    my $j2  = Data::MinHash::Shared->bbit_similarity_of($sig_a, $sig_b, $k, $b);  # compare snapshots

C<add> folds one element in and returns B<1 if it lowered at least one register>
(so it changed the sketch), else B<0>. C<add_many> folds an array reference under
a single write lock. C<similarity> (aliased C<jaccard>) returns the estimated
Jaccard similarity of the two underlying sets as a number between 0 and 1; two
empty sketches are defined as similarity 1. C<merge> updates this sketch in place
to the min-hash of the B<union> of the two sets (element-wise minimum). Both
C<similarity> and C<merge> require C<$other> to have the same C<$k> and croak
otherwise.

=head2 Introspection

    $mh->size;          # k, the number of registers
    $mh->capacity;      # alias for size
    $mh->filled;        # registers that hold a value: 0 if empty, else k
    my @regs = $mh->registers;   # snapshot of the k register values
    $mh->stats;         # { size, filled, ops, mmap_size }

C<filled> counts registers that hold a value (differ from the empty sentinel).
Every C<add> updates all C<k> registers at once, so C<filled> is 0 for a fresh or
cleared sketch and C<k> once any element has been added -- it is really an
emptiness check rather than a fill gauge. C<registers> returns a snapshot of the
raw register values (unsigned integers) taken under the read lock -- useful for
serialising or comparing sketches yourself.

=head2 Lifecycle

    $mh->path; $mh->memfd; $mh->sync; $mh->unlink;

C<sync> flushes the mapping to its backing store (a no-op for anonymous and memfd
sketches); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened sketches) and C<memfd> the backing descriptor.

=head1 SHARING ACROSS PROCESSES

The sketch lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Every process's C<add> folds into the one shared sketch,
so a fleet of workers can each stream part of a set and the merged sketch
reflects them all.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Each C<add> is a short bounded update, so a
crash leaves the sketch consistent up to the last completed operation.
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

L<Data::HyperLogLog::Shared> (cardinality estimation), L<Data::BloomFilter::Shared>
(set membership), and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
