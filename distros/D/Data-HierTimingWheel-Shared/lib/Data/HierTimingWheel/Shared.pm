package Data::HierTimingWheel::Shared;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Data::HierTimingWheel::Shared', $VERSION);

*schedule = \&add;   # zero-overhead alias (same CV via typeglob)

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::HierTimingWheel::Shared - shared-memory hierarchical timing wheel (O(1) timers at any delay)

=head1 SYNOPSIS

    use Data::HierTimingWheel::Shared;

    # 4 levels of 256 slots -> schedules any delay up to 256**4 - 1 ticks
    my $tw = Data::HierTimingWheel::Shared->new(undef, 256, 4, 100_000);

    my $id = $tw->add(30, $job_id);       # fire in 30 ticks
    my $id2 = $tw->add(5_000_000, $late);  # ...or millions of ticks away, still O(1)
    $tw->cancel($id);                      # cancel before it fires

    # advance the clock; each call returns the payloads that came due
    for (1 .. $ticks_elapsed) {
        my @due = $tw->advance(1);
        handle($_) for @due;
    }

    # share the wheel across processes via a backing file
    my $shared = Data::HierTimingWheel::Shared->new("/tmp/timers.htw", 256, 4, 100_000);

=head1 DESCRIPTION

A B<hierarchical timing wheel> in shared memory (the Varghese-Lauck design behind
Linux kernel and Kafka/Netty timers): a timer scheduler where B<scheduling and
cancelling are O(1) at any delay>, from one tick to billions, in a fixed amount
of memory. It is the multi-level generalisation of L<Data::TimingWheel::Shared>:
where the single-level wheel revisits a far-future timer once per rotation, this
one parks it in a coarse level and only touches it as its time approaches.

Time advances in integer B<ticks>. There are C<num_levels> cascading wheels of
C<num_slots> (= S) buckets each; a level-C<k> slot spans C<S**k> ticks, so the
whole structure schedules any delay in C<[1, S**num_levels)>. A timer is placed
in the lowest level whose range covers its delay. On each tick, level 0 fires the
timers in its current slot; when level 0 completes a rotation, the next level's
current slot B<cascades down> -- its timers are redistributed into finer levels
by their remaining delay -- recursively up the levels. A timer with delay C<D>
fires at exactly tick C<D>, just like the single-level wheel, but a far-future
timer costs O(1) instead of one visit per rotation.

Each timer carries an arbitrary 64-bit B<payload> (e.g. a job id) returned when
it fires. Timers live in a fixed pool of C<capacity> slots; scheduling beyond it,
or with a delay at or beyond C<S**num_levels>, croaks.

Because the wheels live in a shared mapping, B<several processes schedule into
and advance one clock>: any process that opens the same backing file, inherits
the anonymous mapping across C<fork>, or reopens a passed memfd shares the same
timers. A write-preferring futex rwlock with dead-process recovery guards
mutation. B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $tw = Data::HierTimingWheel::Shared->new($path, $num_slots, $num_levels, $capacity, $mode);
    my $tw = Data::HierTimingWheel::Shared->new(undef, $num_slots, $num_levels, $capacity);
    my $tw = Data::HierTimingWheel::Shared->new_memfd($name, $num_slots, $num_levels, $capacity);
    my $tw = Data::HierTimingWheel::Shared->new_from_fd($fd);

C<$num_slots> (S, 2..2^16, default 256) is the number of buckets per level, and
C<$num_levels> (L, 1..16, default 4) the number of cascading wheels; together
they set the maximum schedulable delay to C<S**L - 1> ticks (C<num_slots ** num_levels>
must fit in 64 bits, else the constructor croaks). C<$capacity> is the maximum
number of concurrent timers (1..2^24). Memory is C<num_levels * num_slots * 4 +
capacity * 32> bytes plus a fixed header. Choose S and L so that C<S**L> exceeds
your longest delay -- e.g. C<256, 4> covers ~4.3 billion ticks, C<64, 8> covers
~281 trillion. When reopening an existing file or memfd the stored geometry wins
and the caller's arguments are ignored. An optional file B<mode> may be passed as
the last argument to C<new> (e.g. C<0660>) for cross-user sharing; it defaults to
C<0600> (owner-only).

=head2 Scheduling

    my $id = $tw->add($delay, $payload);   # returns a timer id
    my $id = $tw->schedule($delay, $payload); # alias for add
    my $ok = $tw->cancel($id);             # 1 if cancelled, 0 if already fired/invalid

C<add> schedules a timer to fire C<$delay> ticks from now (a delay below 1 is
treated as 1) carrying the integer C<$payload>, and returns a timer id; it croaks
if the timer pool is full or C<$delay> is at or beyond the wheel's range
(C<max_delay + 1>). C<cancel> removes a still-pending timer by its id, returning 1
if it was cancelled or 0 if it had already fired or the id is not active.

=head2 Advancing the clock

    my @due = $tw->advance($ticks);   # advance by $ticks (default 1)
    my @due = $tw->advance;           # advance by one tick

C<advance> moves the wheel forward by C<$ticks> ticks (default 1) and returns the
list of payloads of every timer that came due during those ticks, in fire order.
Timers that fire are removed automatically. Cost is O(ticks + fired) amortised;
cascades happen only when a level rolls over.

=head2 Introspection and lifecycle

    $tw->now;           # absolute tick count since creation (or last clear)
    $tw->count;         # number of pending timers
    $tw->num_slots;     # slots per level (S)
    $tw->num_levels;    # number of levels (L)
    $tw->max_delay;     # largest schedulable delay (S**L - 1)
    $tw->capacity;      # maximum concurrent timers
    $tw->clear;         # cancel all timers and reset the clock to 0
    $tw->stats;         # { now, count, num_slots, num_levels, max_delay, capacity, ops, mmap_size }
    $tw->path; $tw->memfd; $tw->sync; $tw->unlink;

C<clear> cancels every timer and resets the tick counter. C<sync> flushes the
mapping to its backing store (a no-op for anonymous and memfd wheels); C<unlink>
removes the backing file (also callable as C<< Class->unlink($path) >>); C<path>
returns the backing path (C<undef> for anonymous, memfd, or fd-reopened wheels)
and C<memfd> the backing descriptor.

=head1 SHARING ACROSS PROCESSES

The wheels live in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across C<fork>>,
or a B<memfd> passed to an unrelated process and reopened with
C<< new_from_fd($fd) >>. Any process can schedule timers; typically one process
owns advancing the clock and dispatches the fired payloads, while others schedule
and cancel. The tick counter is shared, so all processes agree on "now".

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default; pass an
explicit octal mode (e.g. C<0660>) as the last argument to C<new> for cross-user
sharing. The file is opened with C<O_NOFOLLOW> and C<O_EXCL>, and the header is
validated on attach. Any process granted write access is trusted not to corrupt
the mapping.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership and dead-owner recovery. Scheduling, cancelling, and each tick of an
advance are short bounded list operations, so a crash leaves the wheel consistent
up to the last completed operation. B<Limitation>: PID reuse is not detected
(very unlikely in practice).

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

L<Data::TimingWheel::Shared> (single-level wheel; simpler, for bounded delays),
L<Data::Heap::Shared> (priority queue / exact ordering), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
