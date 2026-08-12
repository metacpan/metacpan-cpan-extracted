package Data::CountMinSketch::Shared;
use strict;
use warnings;
our $VERSION = '0.04';
require XSLoader;
XSLoader::load('Data::CountMinSketch::Shared', $VERSION);

sub CLONE_SKIP { 1 }  # blessed C-pointer handle: never clone into ithreads (double-free)
1;
__END__

=encoding utf-8

=head1 NAME

Data::CountMinSketch::Shared - shared-memory Count-Min sketch for Linux

=head1 SYNOPSIS

    use Data::CountMinSketch::Shared;

    # epsilon (error factor) 0.1%, delta (failure prob) 0.1%, anonymous mapping
    my $cms = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);

    $cms->add("alice");                 # count "alice" once
    $cms->add("bob", 5);                # count "bob" five times

    $cms->estimate("alice");            # 1  (never less than the true count)
    $cms->estimate("bob");              # 5
    $cms->estimate("carol");            # 0  (never added)

    # bulk add in a single lock acquisition (each element counted once)
    $cms->add_many([ map { "user-$_" } 1 .. 1000 ]);

    # merge another sketch of identical geometry (cellwise add -> summed streams)
    my $other = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);
    $other->add_many([ map { "user-$_" } 500 .. 1500 ]);
    $cms->merge($other);

    # share across processes via a backing file
    my $shared = Data::CountMinSketch::Shared->new("/tmp/freq.cms", 0.001, 0.001);

=head1 DESCRIPTION

A Count-Min sketch in shared memory: a compact, fixed-size structure for
B<approximate frequency estimation over a stream>. You add items (optionally
with a count), then ask for the estimated number of times any item has been
added. Memory is proportional to the configured error parameters, not to the
number of distinct items or the size of the items; the sketch never stores the
items themselves, only a small matrix of counters.

The estimate has a one-sided guarantee: it B<never underestimates> the true
count, and overestimates by at most C<epsilon * total> with probability at least
C<1 - delta>, where C<total> is the sum of all increments. (An item never added
estimates as 0 unless hash collisions with other items inflate every one of its
cells.) This makes the sketch ideal for finding heavy hitters and approximate
counts in a stream that is too large to count exactly. One caveat: C<add> does
not saturate, so a single key's counter and the grand total wrap at 2^64 if a
true count ever reaches that (C<merge> saturates instead); the
never-underestimate guarantee holds for all realistic counts.

Each item is hashed once with XXH3 (128-bit); the two 64-bit halves drive one
column per row (C<d>-row double hashing) into a C<d> x C<w> matrix of 64-bit
counters, with C<w> a power of two. C<add> increments the C<d> cells of the item
(one per row); C<estimate> returns the B<minimum> of those C<d> cells -- since
every collision only ever adds to a cell, the smallest cell is the tightest
upper bound, and is exact when at least one of the item's cells suffered no
collision. The matrix width C<w> and depth C<d> are derived from the C<epsilon>
and C<delta> you request.

Because the matrix lives in a shared mapping, B<several processes share one
sketch>: any process that opens the same backing file, inherits the anonymous
mapping across C<fork>, or reopens a passed memfd, sees the others' additions
and contributes its own. A write-preferring futex rwlock with dead-process
recovery guards mutation, so many processes may C<add> and C<estimate>
concurrently. Two sketches of identical geometry can be combined with C<merge>
(cellwise add), which yields a sketch whose counts are the B<sum> of the two
input streams -- the merged estimate of any item equals the sum of its estimates
in the two inputs.

Items are added and queried by their B<byte> content; wide-character strings
(any codepoint above 255) cause a "Wide character" croak -- encode such strings
to bytes first (for example with C<Encode::encode_utf8>). B<Linux-only>.
Requires 64-bit Perl.

=head1 METHODS

=head2 Constructors

    my $cms = Data::CountMinSketch::Shared->new($path, $epsilon, $delta);
    my $cms = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);   # defaults
    my $cms = Data::CountMinSketch::Shared->new($path, 0.001, 0.001, 0660); # opt-in group share
    my $cms = Data::CountMinSketch::Shared->new_memfd($name, $epsilon, $delta);
    my $cms = Data::CountMinSketch::Shared->new_from_fd($fd);
    my $ro  = Data::CountMinSketch::Shared->new_readonly($path);   # frozen file, read-only

C<$path> is the backing file (C<undef> or omitted for an anonymous mapping).
C<$epsilon> is the target error factor and C<$delta> the target failure
probability; both are optional, default to B<0.001>, and must be strictly
between 0 and 1. C<new> and C<new_memfd> croak if C<$epsilon> or C<$delta> is
out of range.

For a file-backed sketch, C<new> accepts an optional fourth argument: the octal
permission mode used when it B<creates> the backing file (default C<0600>,
owner-only). Pass a wider mode such as C<0660> to opt in to sharing the sketch
with another user, typically via a common group. The backing file is always
opened with C<O_NOFOLLOW>, so a pre-existing symlink at C<$path> is refused
rather than followed. The mode is ignored when attaching an already-initialized
file, for anonymous mappings, and for C<new_memfd>/C<new_from_fd>; a file left
behind by an interrupted create is re-initialized and does receive the requested
mode (see L</CRASH SAFETY>).

From C<$epsilon> and C<$delta> the sketch derives its geometry: a width of C<w
= next_power_of_two(ceil(e / epsilon))> columns (with a floor of 2 columns)
and a depth of C<d = ceil(ln(1 / delta))> rows (clamped to the range 1..32).
Rounding the width up to a power of two means the realised error factor at any
given total is typically B<at or below> the configured target. When reopening
an existing file or memfd, the stored geometry wins and the caller's
C<$epsilon>/C<$delta> do not resize it -- but they are still range-checked, so
an out-of-range value croaks. C<new_memfd> creates a Linux memfd (transferable
via its C<memfd> descriptor); C<new_from_fd> reopens one in another process.
The descriptor you pass is duplicated (C<F_DUPFD_CLOEXEC>), so it stays yours
to close and closing it does not disturb the handle. C<new_readonly> opens a
B<frozen> file read-only for lock-free querying (see L</"FROZEN (READ-ONLY)
MODE">).

This is the standard Count-Min sketch (plain cell increments); it does B<not>
use the conservative-update variant, which would make C<merge> unsound. The
plain construction is what guarantees that merging two sketches is exactly
equivalent to having counted both streams into one.

=head2 Adding and estimating

    my $total = $cms->add($item);           # add 1; returns the new grand total
    my $total = $cms->add($item, $n);       # add $n; returns the new grand total
    my $count = $cms->add_many(\@items);     # add 1 per element; returns how many added
    my $est   = $cms->estimate($item);       # estimated count of $item (>= true count)
    $cms->clear;                             # reset every counter (and total) to 0

C<add> hashes C<$item> (taken by its bytes; wide characters croak, encode first)
and increments its C<d> cells by C<$n> (default 1), returning the new grand
B<total> -- the running sum of all increments across all items. C<$n> is an
unsigned integer. C<add_many> takes an array reference and adds each element
once under a single write lock, returning the number of elements added (the
array's length).

C<estimate> returns the estimated number of times C<$item> has been added: the
minimum of its C<d> cells. This value B<never underestimates> the true count,
and exceeds it by at most C<epsilon * total> with probability at least
C<1 - delta>. An item that was never added estimates as 0 unless every one of
its cells happens to collide with other items.

=head2 Merging

    $cms->merge($other);

Folds C<$other>'s counter matrix into C<$cms> by cellwise addition, so C<$cms>
then estimates, for every item, the B<sum> of that item's counts in the two
sketches; C<$cms>'s C<total> likewise becomes the sum of the two totals. Both
sketches must have identical geometry -- the same width and depth, which follows
from constructing both with the same C<$epsilon> and C<$delta> (C<merge> croaks
on a mismatch). C<$other> is read under its own lock into a private snapshot
first, so merging is deadlock-free even if two processes merge each other
concurrently; C<$other> is not modified. Cells that would overflow a 64-bit
counter saturate at the maximum value.

=head2 Introspection and lifecycle

    $cms->total; $cms->width; $cms->depth; $cms->cells; $cms->stats;
    $cms->path; $cms->memfd; $cms->sync; $cms->unlink;   # or Class->unlink($path)

C<total> is the running sum of all increments; C<width> is the column count
C<w> (a power of two); C<depth> is the row count C<d>; C<cells> is C<width *
depth>, the number of counters. C<sync> flushes the mapping to its backing
store (a no-op for anonymous and memfd sketches, which have none); C<unlink>
removes the backing file (also callable as C<< Class->unlink($path) >>) and
croaks if the removal fails -- except when the file is already gone, which is
what you asked for; it is likewise a no-op when there is no backing file
(anonymous or memfd); C<path> returns the backing path (C<undef> for
anonymous, memfd, or fd-reopened sketches) and C<memfd> the backing descriptor
-- the memfd of a C<new_memfd> sketch or the dup'd fd of a C<new_from_fd>
sketch, and -1 for file-backed or anonymous sketches.

=head1 STATS

C<stats()> returns a hashref describing the sketch:

=over 4

=item * C<width> -- the column count C<w> (a power of two).

=item * C<depth> -- the row count C<d>.

=item * C<total> -- the running sum of all increments.

=item * C<cells> -- C<width * depth>, the number of 64-bit counters.

=item * C<epsilon> -- the achieved error factor, C<e / width>. The
per-item overestimate is bounded by C<epsilon * total> (with probability
C<1 - delta>); a smaller value is a tighter bound.

=item * C<delta> -- the achieved failure probability,
C<< exp(-min(depth, width)) >>. This is the chance that the overestimate
exceeds the C<epsilon * total> bound for a given item; a smaller value is a
stronger guarantee. Row I<r> and row I<r+width> always probe the same column,
so rows past C<width> repeat an earlier row and add no independent estimate --
the effective depth is C<< min(depth, width) >>. A very loose C<epsilon>
combined with a very tight C<delta> therefore cannot reach the requested
C<delta>; tighten C<epsilon> (a smaller epsilon raises C<width>) to get
there.

=item * C<ops> -- running count of mutating operations (C<add>, C<add_many>,
C<merge>, C<clear>).

=item * C<mmap_size> -- bytes of the shared mapping.

=item * C<frozen> -- 1 if the sketch has been sealed by C<freeze> (immutable), else 0.

=item * C<readonly> -- 1 if this handle is a read-only view (from C<new_readonly>,
or the handle that called C<freeze>), else 0.

=back

=head1 SHARING ACROSS PROCESSES

The sketch lives in a shared mapping, shared the same three ways as the rest of
the family: a B<backing file> (every process calls C<< new($path, ...) >> on the
same path with matching epsilon and delta), an B<anonymous mapping inherited
across C<fork>>, or a B<memfd> whose descriptor is passed to an unrelated
process (over a UNIX socket via C<SCM_RIGHTS>, or via C</proc/$pid/fd/$n>) and
reopened with C<< new_from_fd($fd) >>. Because the mapping is shared, B<every
process adds into and estimates against the same counter matrix>, so the counts
reflect the combined stream all of them have added.

    # producer and consumer share one sketch with no coordination
    my $cms = Data::CountMinSketch::Shared->new(undef, 0.001, 0.001);   # before fork
    unless (fork) { $cms->add("ev-500") for 1 .. 10; exit }
    wait;
    print $cms->estimate("ev-500"), "\n";   # >= 10 -- the child's adds

=head1 FROZEN (READ-ONLY) MODE

A file-backed sketch can be B<frozen> and then shipped to other machines, where
consumers open it B<read-only> and query it with B<no locking at all>.

    # producer: build, freeze, ship the file
    my $cms = Data::CountMinSketch::Shared->new("/tmp/freq.cms", 0.001, 0.001);
    $cms->add_many(\@known);
    $cms->freeze;                 # seal: now immutable, and $cms itself is read-only
    # ... copy /tmp/freq.cms to another host ...

    # consumer (any process, same architecture): read-only, lock-free
    my $ro = Data::CountMinSketch::Shared->new_readonly("/tmp/freq.cms");
    $ro->estimate($item) for @queries;

C<freeze> takes the write lock, marks the sketch B<permanently immutable>
(there is no unfreeze -- rebuild the file to change it), and flushes the seal
to disk. A frozen sketch rejects every mutator (C<add>, C<add_many>, C<merge>,
C<clear>) with a croak, and a read-write reopen (C<< new($path, ...) >>) of a
sealed file is B<refused> -- so a shipped artifact can never be silently
mutated out from under its readers. That protection is enforced by the reader:
the seal is a header flag that C<0.03> and earlier do not know about, and the
on-disk format version is deliberately unchanged so those releases can still
open files written here. A pre-C<0.04> build therefore opens a sealed file
read-write and can modify it, so keep producers and consumers on C<0.04> or
later if you rely on the seal. C<freeze> itself is not idempotent: the handle
that seals the file becomes a read-only view of it, so calling C<freeze> on
that handle again croaks.

C<new_readonly($path)> maps the file C<O_RDONLY> / C<PROT_READ> and B<requires it
to be frozen> (it croaks on a file that was never C<freeze>d). Because a sealed
sketch's cells and geometry are immutable, C<estimate>, C<total> and C<stats>
read them B<directly, taking no reader lock> -- the mapping is never written, so
a read-only view works from a read-only file descriptor or a read-only
filesystem, and any number of processes can share one C<PROT_READ> mapping.
C<frozen> and C<readonly> report the two states.

B<Portability.> The on-disk format is native binary (native-endian 64-bit
words), so a frozen file may be copied only between machines of the B<same
architecture>; a wrong-endian file is rejected at open by the magic check.
B<Copy the file to each consumer> -- do not share one file over a network
filesystem: the lock is a Linux futex (process-local to one kernel), and the
"no live writer" contract assumes a static copy. Linux-only; 64-bit Perl.

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only
the creating user can open and attach them. To share a backing file across
users, pass an explicit octal file mode such as C<0660> as the last argument
to C<new>; the mode is applied when the file is created, and when a file left
behind by an interrupted create is re-initialized (see L</CRASH SAFETY>); a
file already in use keeps its own permissions. The file is opened with
C<O_NOFOLLOW>, so a symlink planted at the path is refused, and created with
C<O_EXCL>; the on-disk header is validated when the file is attached. Any
process you grant write access to a shared mapping is trusted not to corrupt
its contents while other processes are using it.

=head1 CRASH SAFETY

Mutation is guarded by a futex-based write-preferring rwlock with PID-encoded
ownership; if a holder dies, the next contender detects the dead owner and
recovers. Each cell increment is a single word store, so a crash leaves the
sketch consistent up to the last completed C<add>.
B<Limitation>: PID reuse is not detected (very unlikely in practice).

Reader-slot exhaustion (slotless readers): dead-process recovery attributes a
crashed lock holder's contribution through its reader-slot. The slot table
holds 1024 entries (one per concurrent reader process). If more than that many
reader processes share one mapping at once, a reader that cannot claim a slot
proceeds "slotless" -- it still takes the read lock but leaves no per-process
record. If such a slotless reader is then killed while holding the read lock,
its share of the lock cannot be attributed to a dead process, so writer
recovery cannot reclaim it and writers may block until the mapping is
recreated. Reaching this needs more than 1024 concurrent reader processes on
one mapping plus a crash in the brief read-lock window; the dead-process slot
reclaim keeps the table from filling with stale entries, so in practice it is
very unlikely. Those preconditions cover the live-process route only. The
count lives in the mapping and C<new> validates the geometry, not this
transient value, so a backing file damaged at rest -- bit rot, a partial copy,
or a process that scribbled on the mapping -- can present a non-zero slotless
count and block every writer the same way, with none of the above. If writers
hang on a file no live reader is using, recreate it.

An interrupted create is recovered too. A creator killed after the backing
file is sized but before its header is committed leaves a full-size, all-zero
file. C<new> re-initializes such a file automatically, but only when it is
exactly the size the requested geometry needs, is owned by your effective uid,
and is still entirely zero -- a file holding data is never re-initialized. If
the creator got as far as writing part of the header, the file cannot be told
apart from a corrupt one and C<new> croaks with C<incomplete Count-Min sketch
file left by an interrupted create; remove it and retry>. Such a file never
held any data, so removing it is safe.

B<Disk space.> The backing file is created B<sparse>: C<new> sizes it, but
blocks are allocated only as you write, so a large sketch costs almost
nothing on disk until it is used. The cost of that is a late failure, and how
it reaches you depends on the filesystem. Where blocks are allocated at fault
time -- tmpfs, so C</dev/shm> and many C</tmp> mounts -- a write to a page that
cannot be backed raises C<SIGBUS> and kills the process, because an C<mmap>
store has no way to report C<ENOSPC>. Where allocation is delayed to writeback
(ext4, xfs), the store lands in page cache and the failure appears later: the
write is lost, and C<sync> is what reports it, croaking with the underlying
error. Keep the filesystem sized for the sketch you asked for, and call
C<sync> when you need to know your writes reached disk.

=head1 SEE ALSO

L<Data::BloomFilter::Shared>, L<Data::HyperLogLog::Shared>,
L<Data::Intern::Shared>, L<Data::SortedSet::Shared>,
L<Data::SpatialHash::Shared>, and the rest of the C<Data::*::Shared> family.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
