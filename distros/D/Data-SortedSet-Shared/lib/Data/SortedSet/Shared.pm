package Data::SortedSet::Shared;
use strict;
use warnings;
our $VERSION = '0.04';
require XSLoader;
XSLoader::load('Data::SortedSet::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)

# String-keyed sets: members are arbitrary byte strings instead of int64 ids.
# Convenience constructor that builds a Data::SortedSet::Shared::Strings, which
# interns keys to ids via Data::Intern::Shared.
sub new_strings {
    my $class = shift;
    require Data::SortedSet::Shared::Strings;
    return Data::SortedSet::Shared::Strings->new(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::SortedSet::Shared - shared-memory sorted set (ZSET) for Linux

=head1 SYNOPSIS

    use Data::SortedSet::Shared;

    # up to 1M members, anonymous shared mapping
    my $z = Data::SortedSet::Shared->new(undef, 1_000_000);

    $z->add(42, 1500);              # member 42 with score 1500
    $z->add(7,  1500);              # ties broken by member id
    $z->incr(42, 50);               # 42 -> 1550 (returns the new score)

    my @top   = $z->rev_range_by_rank(0, 9);    # top 10 members (highest score)
    my $rank  = $z->rank(42);                    # 0-based rank (lowest score = 0)
    my $score = $z->score(42);
    my @near  = $z->range_by_score(1400, 1600);  # members scored in [1400, 1600]

    my ($m, $s) = $z->pop_min;       # remove + return the lowest

    $z->each(sub { my ($member, $score) = @_; ... });   # in score order

=head1 DESCRIPTION

An ordered set in shared memory, in the spirit of a Redis sorted set: each
B<member> is a 64-bit integer carrying a B<double score>, and members are kept in
score order.  It is backed by an order-statistics B+tree -- so C<rank>, range,
and C<pop> are O(log n) and ranges scan sequentially through doubly-linked leaves
-- paired with a member-to-score hash index, so C<score> and C<exists> are O(1).

The total order is B<(score, member)>: members with equal scores are ordered by
member id, which gives a well-defined rank and a deterministic
C<pop_min>/C<pop_max>.

Multiple processes can map the same set and read and write it concurrently;
access is serialized by a write-preferring futex rwlock that recovers
automatically if a lock holder dies (see L</CRASH SAFETY>).

Members are 64-bit integers.  For B<string-keyed> sets, see L</String-keyed sets>
and L<Data::SortedSet::Shared::Strings> (bundled).  Scores must not be NaN.
B<Linux-only>.  Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $z = Data::SortedSet::Shared->new($path, $max [, $mode]);
    my $z = Data::SortedSet::Shared->new(undef, $max);        # anonymous
    my $z = Data::SortedSet::Shared->new_memfd($name, $max);
    my $z = Data::SortedSet::Shared->new_from_fd($fd);

C<$path> is the backing file (C<undef> for an anonymous mapping); C<$max> is the
maximum number of members.  When reopening an existing file or memfd, the stored
header wins and the caller's C<$max> is ignored.  Backing files are created with
mode 0600 by default; pass an octal C<$mode> (e.g. C<0660>) to opt into cross-user
sharing.  The mode applies only when the file is created (it is ignored when
attaching an existing file); the exact mode is applied via C<fchmod>, so umask does not narrow it.  C<new_memfd> creates a Linux
memfd (transferable via its C<memfd> descriptor); C<new_from_fd> reopens one in
another process.

=head2 String-keyed sets

    my $z = Data::SortedSet::Shared->new_strings(max => 1_000_000);
    $z->add("alice", 1500);
    my @top = $z->rev_range_by_rank(0, 9);    # ("alice", ...)

C<new_strings> returns a L<Data::SortedSet::Shared::Strings> -- the same API as
this class but with B<string members>.  Keys are interned to dense ids via
L<Data::Intern::Shared> (a prerequisite of this distribution), so the set is still
shared across processes by id.  Ties among equal scores break by interning id, not
lexicographically.  See L<Data::SortedSet::Shared::Strings> for the full options
(C<set>/C<keys> backing paths, C<max_keys>, C<arena>, C<mode>), and the separate
C<wrap> constructor that adopts two existing objects.

=head2 Mutators

    $z->add($member, $score);     # 1 new, 0 existing (score updated), undef if full
    $z->incr($member, $delta);    # add to the score (creating at $delta); returns new score
    $z->remove($member);          # true if removed, false if absent
    my $n = $z->add_many([ [$m1,$s1], [$m2,$s2], ... ]);   # bulk; returns count of new
    $z->clear;

C<add> inserts a new member or updates an existing member's score, returning 1 or
0 respectively, or C<undef> if the pool is full and the member is new.  C<$score>
may be any finite or infinite value but B<not NaN> (croaks).  C<incr> creates an
absent member at C<$delta> (like Redis ZINCRBY) and croaks if the result would be
NaN, or if the pool is full and the member is new.

C<add_many> applies a whole batch under a single lock; each row is an
C<[member, score]> arrayref, malformed or NaN-scored rows are skipped, and it
stops at C<$max>.  It returns the number of members B<newly inserted>, which can
be fewer than the number of new rows if the pool fills mid-batch.

=head2 Lookup and count

    $z->score($member);           # the score, or undef if absent
    $z->exists($member);
    $z->count;                    # number of members
    $z->rank($member);            # 0-based rank (lowest score = 0), or undef
    $z->rev_rank($member);        # rank from the top, or undef
    $z->count_in_score($min, $max);   # members with score in [min, max] (inclusive)

=head2 Rank and range

    $z->at_rank($r);              # member at rank $r (negative counts from the end), or undef
    my @m = $z->range_by_rank($start, $stop);       # members in [start .. stop] by rank
    my @m = $z->rev_range_by_rank(0, 9);            # top 10 (highest scores first)
    my @m = $z->range_by_score($min, $max, %opts);  # members scored in [min, max], ascending
    my @m = $z->rev_range_by_score($max, $min, %opts);

Rank indices are 0-based and may be negative (counting from the end, like Perl
slices); C<range_by_*> bounds are B<inclusive>.  C<range_by_score> /
C<rev_range_by_score> accept C<< limit => $n >> and C<< offset => $k >> (a
negative C<offset> is treated as 0).  All
range and rank methods return B<members>; pass C<< withscores => 1 >> for a flat
C<(member, score, ...)> list instead.

=head2 Pop and peek

    my ($member, $score) = $z->pop_min;    # remove + return the lowest, or () if empty
    my ($member, $score) = $z->pop_max;
    my ($member, $score) = $z->peek_min;   # without removing
    my ($member, $score) = $z->peek_max;

=head2 Iteration

    $z->each(sub { my ($member, $score) = @_; ... });

C<each> snapshots all members under the read lock, then invokes the callback once
per member in score order after the lock is released, so the callback may safely
call back into the set.

=head2 Introspection and lifecycle

    $z->count; $z->max_entries; $z->stats;     # see STATS
    $z->path; $z->memfd; $z->sync; $z->unlink;     # or Class->unlink($path)
    $z->eventfd; $z->fileno; $z->notify; $z->eventfd_consume;

C<sync> flushes the mapping to its backing store and C<unlink> removes the
backing file (also callable as C<< Class->unlink($path) >>).  C<path> returns the
backing file path (C<undef> for an anonymous or memfd-backed set) and C<memfd>
returns the descriptor of a C<new_memfd> set (-1 otherwise).  The eventfd methods
let another process wait for updates: C<eventfd> lazily creates an eventfd and
returns its descriptor (croaks on failure; calling it again returns the same fd),
C<fileno> returns the current eventfd descriptor or -1, C<notify> writes a wakeup
(returning false if no eventfd is attached), and C<eventfd_consume> reads and
resets the counter, returning it as an integer or C<undef> when nothing is
pending.

=head1 SHARING ACROSS PROCESSES

The set lives in a shared mapping, so several processes operate on the same data
with no serialization layer in between.  There are three ways to share it:

=over 4

=item *

B<A backing file> -- every process calls C<< new($path, $max) >> on the same
path.  The first to arrive creates and sizes the file (serialized by an exclusive
lock); the rest map it.

=item *

B<An anonymous mapping inherited across C<fork>> -- create with
C<< new(undef, $max) >> before forking; the parent and its children then share
the one mapping.

=item *

B<A memfd> -- create with C<< new_memfd($name, $max) >> and hand its C<memfd>
descriptor to an unrelated process (over a UNIX socket with C<SCM_RIGHTS>, or
while the creator is alive via C</proc/$pid/fd/$n>), which reopens it with
C<< new_from_fd($fd) >>.

=back

    # children populate a fork-shared set; the parent reads the result
    my $z = Data::SortedSet::Shared->new(undef, 1_000_000);
    for my $k (1 .. 4) {
        unless (fork) {                                  # child
            $z->add($k * 1_000_000 + $_, rand) for 1 .. 1000;
            exit;
        }
    }
    1 while wait != -1;                                  # reap children
    print $z->count, "\n";                               # 4000

Every operation is serialized by the rwlock, so concurrent writers do not corrupt
the tree.  A writer can wake readers blocked in other processes through the
eventfd interface: it calls C<notify> after a batch, and a reader selects on
C<fileno> then drains the count with C<eventfd_consume>.

=head1 COMPLEXITY

C<score>/C<exists>/C<peek_*> are O(1); C<add>/C<remove>/C<incr>/C<rank>/
C<at_rank>/C<pop_*> and locating a range bound are O(log n); a range or iteration
of C<k> members is O(log n + k), scanning sequentially through the linked leaves.

=head1 STATS

C<stats()> returns a hashref with keys: C<count>, C<max_entries>, C<height>
(B+tree height), C<node_capacity>, C<nodes_used>, C<index_slots>, C<index_load>
(occupied fraction of the member index), C<ops> (running count of write-path
calls, whether or not they changed the set), and C<mmap_size> (bytes).

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

The write lock is a futex-based rwlock with PID-encoded ownership; if a writer
dies while holding it, the next writer detects the dead owner and recovers.
Reader slots are reclaimed similarly.  Recovery restores B<locking only>, never
tree consistency: a writer killed mid-mutation (a node split, underflow, or
insert) can leave the B+tree structurally corrupt.  B<Limitation>: PID reuse is
not detected, which is very unlikely in practice but cannot be ruled out.

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

L<Data::SortedSet::Shared::Strings> (string-keyed variant, bundled with this
distribution), L<Data::Intern::Shared>, L<Data::SpatialHash::Shared>,
L<Data::HashMap::Shared>, L<Data::Heap::Shared>, L<Data::Graph::Shared>, and the
rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
