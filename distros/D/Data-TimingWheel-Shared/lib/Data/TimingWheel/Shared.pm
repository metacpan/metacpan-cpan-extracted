package Data::TimingWheel::Shared;
use strict;
use warnings;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load('Data::TimingWheel::Shared', $VERSION);

*schedule = \&add;   # zero-overhead alias (same CV via typeglob)

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::TimingWheel::Shared - shared-memory hashed timing wheel (O(1) timer scheduling)

=head1 SYNOPSIS

    use Data::TimingWheel::Shared;

    # a wheel of 512 slots holding up to 10_000 concurrent timers
    my $tw = Data::TimingWheel::Shared->new(undef, 512, 10_000);

    my $id = $tw->add(30, $job_id);   # fire in 30 ticks, carrying a payload
    $tw->cancel($id);                 # ... or cancel it before it fires

    # advance the clock; each call returns the payloads that came due
    for (1 .. $ticks_elapsed) {
        my @due = $tw->advance(1);
        handle($_) for @due;
    }

    # share the wheel across processes via a backing file
    my $shared = Data::TimingWheel::Shared->new("/tmp/timers.tw", 512, 10_000);

=head1 DESCRIPTION

A B<hashed timing wheel> in shared memory: a timer scheduler where B<scheduling
and cancelling a timer are O(1)> regardless of how many timers are outstanding,
the data structure behind efficient timeout management in event loops, network
stacks, and job schedulers. It complements a heap-based priority queue
(L<Data::Heap::Shared>): a heap gives exact ordering at O(log n) per operation,
while a timing wheel gives O(1) scheduling when timers are expressed in discrete
B<ticks>.

Time advances in integer B<ticks>. Scheduling a timer for C<delay> ticks places
it in bucket C<(now + delay) mod num_slots>; a timer whose delay exceeds one full
rotation of the wheel carries a "rounds" counter that is decremented each time
the hand sweeps its bucket, firing only when it reaches zero. Each timer carries
an arbitrary 64-bit B<payload> (e.g. a job id) that is returned to you when the
timer fires. Timers live in a fixed pool of C<capacity> slots; scheduling beyond
it croaks.

Because the wheel lives in a shared mapping, B<several processes schedule into
and advance one clock>: any process that opens the same backing file, inherits
the anonymous mapping across C<fork>, or reopens a passed memfd shares the same
timers. A write-preferring futex rwlock with dead-process recovery guards
mutation. B<Linux-only>. Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $tw = Data::TimingWheel::Shared->new($path, $num_slots, $capacity, $mode);
    my $tw = Data::TimingWheel::Shared->new(undef, $num_slots, $capacity);
    my $tw = Data::TimingWheel::Shared->new_memfd($name, $num_slots, $capacity);
    my $tw = Data::TimingWheel::Shared->new_from_fd($fd);

C<$num_slots> is the wheel resolution -- the number of buckets, i.e. how many
distinct ticks fit in one rotation (1..2^24). C<$capacity> is the maximum
number of concurrent timers (1..2^24). For O(1) firing, choose C<$num_slots>
at least as large as your longest common delay so most timers fire within one
rotation. Memory is C<num_slots * 4 + capacity * 32> bytes plus a fixed
header. C<new> and C<new_memfd> croak on out-of-range arguments. When
reopening an existing file or memfd the stored geometry wins and the caller's
arguments do not resize it -- but they are still range-checked, so an
out-of-range value croaks. An optional file B<mode> may be passed as the last
argument to C<new> (e.g. C<0660>) for cross-user sharing; it defaults to
C<0600> (owner-only).

=head2 Scheduling

    my $id = $tw->add($delay, $payload);   # returns a timer id
    my $id = $tw->schedule($delay, $payload); # alias for add
    my $ok = $tw->cancel($id);             # 1 if cancelled, 0 if already fired/invalid

C<add> schedules a timer to fire C<$delay> ticks from now (a delay below 1,
including a negative delay, is treated as 1) carrying the integer C<$payload>,
and returns an opaque timer id; it croaks if the timer pool is full. C<cancel>
removes a still-pending timer by its id, returning 1 if it was cancelled or 0 if
it had already fired or the id is not active. A timer id carries a generation
tag, so cancelling a stale id whose slot has since been reused correctly returns
0 rather than cancelling the unrelated timer now occupying that slot.

=head2 Advancing the clock

    my @due = $tw->advance($ticks);   # advance by $ticks (default 1)
    my @due = $tw->advance;           # advance by one tick

C<advance> moves the wheel forward by C<$ticks> ticks (default 1; must be >= 0 --
a negative count croaks) and returns the list of payloads of every timer that
came due during those ticks, in fire order.
Timers that fire are removed from the wheel automatically. Cost is O(ticks +
fired) plus, for long timers, one visit per rotation.

=head2 Introspection and lifecycle

    $tw->now;           # absolute tick count since creation (or last clear)
    $tw->count;         # number of pending timers
    $tw->num_slots;     # wheel resolution
    $tw->capacity;      # maximum concurrent timers
    $tw->clear;         # cancel all timers and reset the clock to 0
    $tw->stats;         # { now, count, num_slots, capacity, cur, ops, mmap_size }
    $tw->path; $tw->memfd; $tw->sync; $tw->unlink;

C<clear> cancels every timer and resets the tick counter. C<sync> flushes the
mapping to its backing store (a no-op for anonymous and memfd wheels); C<unlink>
removes the backing file (also callable as C<< Class->unlink($path) >>); C<path>
returns the backing path (C<undef> for anonymous, memfd, or fd-reopened wheels)
and C<memfd> the backing descriptor.

=head1 SHARING ACROSS PROCESSES

The wheel lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file>, an B<anonymous mapping inherited across
C<fork>>, or a B<memfd> passed to an unrelated process and reopened with C<<
new_from_fd($fd) >>. The descriptor you pass is duplicated
(C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it does not
disturb the handle. Any process can schedule timers; typically one process
owns advancing the clock and dispatches the fired payloads, while others
schedule and cancel. The tick counter is shared, so all processes agree on
"now".

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

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete timing-wheel file
left by an interrupted create; remove it and retry>. A file left behind by an
interrupted create never held data, so removing it is safe -- but a file whose
header was corrupted after the fact reaches the same croak, so confirm it is
an abandoned create before deleting anything you care about.

=head1 SEE ALSO

L<Data::Heap::Shared> (priority queue / exact ordering), and the rest of the
C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
