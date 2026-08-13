package Data::TopK::Shared;
use strict;
use warnings;
our $VERSION = '0.04';
require XSLoader;
XSLoader::load('Data::TopK::Shared', $VERSION);

*observe = \&add;   # zero-overhead alias (same CV via typeglob)

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::TopK::Shared - shared-memory top-k heavy hitters (Space-Saving, optional time decay)

=head1 SYNOPSIS

    use Data::TopK::Shared;

    # track the 100 most frequent keys of a stream
    my $tk = Data::TopK::Shared->new(undef, 100);

    $tk->add($_) for @stream;           # feed keys one at a time

    for my $h (@{ [ $tk->top(10) ] }) { # the 10 heaviest, count-descending
        printf "%s: ~%d (+/- %d)\n", $h->{key}, $h->{count}, $h->{error};
    }

    my $est = $tk->estimate("popular"); # estimated count of one key (0 if untracked)

    # share the summary across processes via a backing file
    my $shared = Data::TopK::Shared->new("/tmp/hitters.tk", 100);

    # time-decayed: recent hits outweigh old ones (half-life 3600 time units)
    my $decayed = Data::TopK::Shared->new_decayed(undef, 100, 256, 3600);
    $decayed->add($key, $epoch_seconds);   # optional timestamp; else a per-add tick
    $decayed->top(10);                      # the heaviest *recent* hitters

=head1 DESCRIPTION

A B<top-k heavy hitters> summary in shared memory: with a fixed set of C<capacity>
counters it tracks the most frequent keys of a stream and estimates each one's
frequency, using the B<Space-Saving> algorithm, in memory that does not grow with
the stream. This is the standard way to find the top talkers, hot URLs, busiest
source IPs, or most-frequent search terms without storing a per-key counter for
every distinct key seen.

Feed keys with C<add>. While a counter is free a new key claims it; once all
C<capacity> counters are in use, a new key B<evicts the smallest counter> and
takes over its count as an over-estimate bound. Consequently each monitored key
carries a C<count> (an upper bound) and an C<error> (the maximum over-estimate),
so its true frequency lies in C<[count - error, count]>. Any key whose true
frequency exceeds C<total_observations / capacity> is B<guaranteed> to be
retained -- the genuine heavy hitters never fall out.

Because the summary lives in a shared mapping, B<several processes feed one
top-k>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd contributes to and reads the
same counters. A write-preferring futex rwlock with dead-process recovery guards
mutation.

Keys are handled by their B<byte> content, truncated to C<key_size> bytes
(default 256): two keys sharing a C<key_size>-byte prefix are counted as one.
Wide-character strings (any codepoint above 255) cause a "Wide character" croak
-- encode to bytes first. B<Linux-only>. Requires 64-bit Perl.

=head2 Time decay (recent hitters)

A summary created with C<new_decayed($path, $capacity, $key_size, $half_life)>
keeps a B<time-decayed> top-k: an observation's contribution B<halves every
C<$half_life> time units>, so recent activity dominates and stale heavy hitters
fade out. It uses B<forward decay> (Efraimidis / Cormode): counts are stored as
decayed weights so the Space-Saving min-heap stays consistent, with an occasional
internal landmark rescale to keep the weights bounded (no unbounded growth). Feed
it with C<< $tk->add($key, $timestamp) >> -- C<$timestamp> is any non-decreasing
number in your own units (epoch seconds, milliseconds, an event index); if you
omit it, time advances one B<tick> per C<add>. A past (smaller) timestamp does not
rewind the clock. C<estimate>, C<error>, and C<top> then report B<decayed> counts
(floating point) as of the latest time seen; everything else -- eviction bounds,
cross-process sharing, C<clear> -- works the same. A plain (non-decayed) summary
is unchanged and on-disk compatible.

=head1 METHODS

=head2 Constructors

    my $tk = Data::TopK::Shared->new($path, $capacity, $key_size, $mode);
    my $tk = Data::TopK::Shared->new(undef, $capacity);            # anonymous, key_size 256
    my $tk = Data::TopK::Shared->new_memfd($name, $capacity, $key_size);
    my $tk = Data::TopK::Shared->new_from_fd($fd);

    # time-decayed (forward decay) -- extra half_life argument
    my $tk = Data::TopK::Shared->new_decayed($path, $capacity, $key_size, $half_life);
    my $tk = Data::TopK::Shared->new_decayed_memfd($name, $capacity, $key_size, $half_life);

C<new_decayed> / C<new_decayed_memfd> take a final C<$half_life> (a finite
number greater than 0, in whatever time units you feed to C<add>): a
contribution's weight halves every C<$half_life> units. They croak on a
non-positive or non-finite half-life. C<$capacity> is the number of counters
(the maximum number of keys tracked at once, at least 1, up to 2^24) -- pick
it a few times larger than the number of heavy hitters you want to reliably
capture. C<$key_size> is the maximum bytes stored per key (default 256; longer
keys are truncated). Memory is roughly C<capacity * (40 + key_size)> bytes
plus a fixed header. C<new> and C<new_memfd> croak on a capacity below 1 or
above 2^24, or a C<$key_size> outside 1..4096. When reopening an existing file
or memfd the stored geometry wins and the caller's arguments do not resize it
-- but they are still range-checked, so an out-of-range value croaks. An
optional file B<mode> may be passed as the last argument to C<new> (e.g.
C<0660>) for cross-user sharing; it defaults to C<0600> (owner-only).

=head2 Feeding and querying

    my $count = $tk->add($key);           # observe one key; returns its new estimated count
    my $count = $tk->add($key, $t);       # decayed mode: observe at time $t (optional)
    $tk->observe($key);                   # alias for add
    my $n     = $tk->add_many(\@keys);    # observe a batch under one lock; returns the batch size
    my @top   = $tk->top($k);             # the $k heaviest as hashrefs, count-descending
    my @all   = $tk->top;                 # all tracked keys (k defaults to every counter)
    my $est   = $tk->estimate($key);      # estimated count of one key, 0 if untracked
    my $err   = $tk->error($key);         # the over-estimate bound for that key (0 if exact/untracked)
    $tk->clear;                           # forget everything (counters and totals reset)

C<add> observes one key and returns its B<estimated count after> the observation.
C<add_many> feeds an array reference under a single write lock. C<top> returns a
list of hash references C<< { key => $bytes, count => $n, error => $e } >> sorted
by C<count> descending (ties broken by tighter C<error> first); with no argument,
or an argument larger than the number tracked, it returns every tracked key.
C<estimate> returns the upper-bound count for a single key (0 if it is not
currently tracked); C<error> returns that key's over-estimate bound, so its true
count lies in C<[estimate - error, estimate]>. To read a key's count and error as
a consistent pair under one lock, use the hashref C<top> returns for it.

=head2 Introspection

    $tk->capacity;      # number of counters
    $tk->key_size;      # max bytes stored per key
    $tk->tracked;       # keys currently tracked: min(distinct seen, capacity)
    $tk->seen;          # total observations fed
    $tk->is_decayed;    # true for a time-decayed summary
    $tk->half_life;     # the decay half-life (0 for a plain summary)
    $tk->stats;         # { capacity, key_size, tracked, seen, ops, mmap_size, decayed[, half_life] }

C<is_decayed> reports whether the summary is time-decayed; C<half_life> returns its
half-life (0 for a plain summary). In decayed mode C<estimate>, C<error>, and the
C<count>/C<error> fields of C<top> are B<decayed> counts (floating point) as of the
latest observed time; C<stats> gains C<decayed> (and C<half_life> when decayed).

=head2 Lifecycle

    $tk->path; $tk->memfd; $tk->sync; $tk->unlink;

C<sync> flushes the mapping to its backing store (a no-op for anonymous and memfd
summaries); C<unlink> removes the backing file (also callable as
C<< Class->unlink($path) >>); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened summaries) and C<memfd> the backing descriptor.

=head1 ACCURACY

Space-Saving gives one-sided guarantees. Every key's C<count> is an B<upper
bound> on its true frequency, and its true frequency is at least C<count - error>.
Any key whose true frequency exceeds C<seen / capacity> is guaranteed to be among
the tracked keys, so with C<capacity> comfortably larger than the number of
genuine heavy hitters, the top of the list is exact and only the long tail is
approximate. Increasing C<capacity> tightens the error on the marginal keys.

=head1 SHARING ACROSS PROCESSES

The summary lives in a shared mapping, shared the same three ways as the rest
of the family: a B<backing file>, an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> passed to an unrelated process and reopened with C<<
new_from_fd($fd) >>. The descriptor you pass is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the handle. Every process's C<add> feeds the one shared summary, so a
fleet of workers can each process part of a stream into a single top-k.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Each C<add> is a short bounded update, so a
crash leaves the summary consistent up to the last completed operation.
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

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete top-k table file
left by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 SEE ALSO

L<Data::CountMinSketch::Shared> (per-key frequency estimation),
L<Data::Reservoir::Shared> (uniform sampling), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
