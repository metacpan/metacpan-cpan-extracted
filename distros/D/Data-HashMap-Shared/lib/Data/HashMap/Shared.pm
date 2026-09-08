package Data::HashMap::Shared;
use strict;
use warnings;
our $VERSION = '0.20';

require XSLoader;
XSLoader::load('Data::HashMap::Shared', $VERSION);

# ithreads: blessed shared-memory handles must never be cloned into a
# child thread -- the clone would double-free the handle on thread exit.
my @VARIANTS = qw(I16 I16S I32 I32S II IS SI SI16 SI32 SS);
{ no strict 'refs';
  for my $v (@VARIANTS) {
      *{"Data::HashMap::Shared::${v}::CLONE_SKIP"}         = sub { 1 };
      *{"Data::HashMap::Shared::${v}::Cursor::CLONE_SKIP"} = sub { 1 };
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

Data::HashMap::Shared - Multiprocess shared-memory hash maps with LRU eviction
and per-key TTL

=head1 SYNOPSIS

    use Data::HashMap::Shared::II;

    # Create or open a shared map (file-backed mmap)
    my $map = Data::HashMap::Shared::II->new('/tmp/mymap.shm', 100000);

    # Keyword API (fastest)
    shm_ii_put $map, 42, 100;
    my $val = shm_ii_get $map, 42;

    # Method API
    $map->put(42, 100);
    my $v = $map->get(42);

    # Atomic counters (under the read lock, without LRU or TTL)
    shm_ii_incr $map, 1;            # 1
    shm_ii_incr_by $map, 1, 10;     # 11
    shm_ii_max $map, 1, 50;         # monotonic: store max(current, 50) -> 50

    # Compare-and-swap (all variants; byte-compare for string values)
    shm_ii_cas $map, 1, 50, 42;     # swap to 42 only if current == 50

    # LRU cache (evicts least-recently-used when full)
    my $cache = Data::HashMap::Shared::II->new('/tmp/cache.shm', 100000, 1000);
    shm_ii_put $cache, 42, 100;    # auto-evicts LRU entry if size > 1000

    # TTL (entries expire after N seconds)
    my $ttl_map = Data::HashMap::Shared::II->new('/tmp/ttl.shm', 100000, 0, 60);
    shm_ii_put $ttl_map, 1, 10;          # expires in 60s
    shm_ii_put_ttl $ttl_map, 2, 20, 5;   # per-key: expires in 5s

    # Multiprocess
    if (fork() == 0) {
        my $child = Data::HashMap::Shared::II->new('/tmp/mymap.shm', 100000);
        shm_ii_incr $child, 1;   # atomic increment visible to parent
        exit;
    }
    wait;

=head1 DESCRIPTION

Data::HashMap::Shared provides type-specialized hash maps stored in
file-backed shared memory (C<mmap(MAP_SHARED)>), enabling efficient
multiprocess data sharing on Linux. With opt-in B<LRU eviction> and
B<per-key TTL> it doubles as a fast cross-process B<cache>; lookups take a
lock-free seqlock fast path.

B<Linux-only>. Requires 64-bit Perl.

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Futex-based read-write lock (fast userspace path)

=item * Atomic counters (incr/decr under the read lock on maps without LRU or TTL)

=item * Elastic capacity (starts small, grows/shrinks automatically)

=item * Arena allocator for string storage in shared memory

=item * Keyword API via XS::Parse::Keyword for maximum speed

=item * Opt-in B<LRU eviction> -- clock/second-chance algorithm; reads stay lock-free

=item * Opt-in B<per-key TTL> expiry -- lazy removal on access; monotonic clock

=item * Stale lock recovery for both writers and readers (dead PIDs detected and drained automatically)

=back

=head2 Variants

=over

=item L<Data::HashMap::Shared::I16> - int16 to int16

=item L<Data::HashMap::Shared::I32> - int32 to int32

=item L<Data::HashMap::Shared::II> - int64 to int64

=item L<Data::HashMap::Shared::I16S> - int16 to string

=item L<Data::HashMap::Shared::I32S> - int32 to string

=item L<Data::HashMap::Shared::IS> - int64 to string

=item L<Data::HashMap::Shared::SI16> - string to int16

=item L<Data::HashMap::Shared::SI32> - string to int32

=item L<Data::HashMap::Shared::SI> - string to int64

=item L<Data::HashMap::Shared::SS> - string to string

=back

=head2 Integer Range and Wrapping

Integer keys and values are stored as fixed-width two's-complement
integers: C<I16>/C<SI16>/C<I16S> use a signed 16-bit range
(-32768 .. 32767), C<I32>/C<SI32>/C<I32S> a signed 32-bit range, and
C<II>/C<IS>/C<SI> a signed 64-bit range. A key or value outside the
variant's range is B<silently truncated> to the low bits (two's
complement), with no warning: on an C<I16> map, C<< $map->put(70000, ...) >>
stores under key C<4464> (C<70000 & 0xFFFF>), so C<get(70000)> and
C<get(4464)> address the same entry. C<incr>/C<decr> wrap the same way
(C<32767 + 1> becomes C<-32768>). Pick a variant wide enough for your data.

=head2 Constructor

    my $map = Data::HashMap::Shared::II->new($path, $max_entries);
    my $map = Data::HashMap::Shared::II->new(undef, $max_entries);    # anonymous
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size);
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size, $ttl);
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size, $ttl, $lru_skip);
    my $map = Data::HashMap::Shared::SS->new($path, $max_entries, 0, 0, 0, $arena_cap); # explicit arena bytes
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size, $ttl, $lru_skip, $arena_cap, $file_mode);
    my $map = Data::HashMap::Shared::II->new_sharded($prefix, $shards, $max_entries, $max_size, $ttl, $lru_skip, $arena_cap, $file_mode);
    my $map = Data::HashMap::Shared::II->new_memfd($name, $max_entries, ...); # memfd-backed
    my $map = Data::HashMap::Shared::II->new_from_fd($fd);            # reopen memfd
    my $fd  = $map->memfd;                                            # -1 if not memfd

Creates or opens a shared hash map backed by file C<$path>. Passing C<undef>
as the path creates an anonymous C<MAP_SHARED|MAP_ANONYMOUS> mapping that is
inherited across C<fork> but has no filesystem presence.

C<new_memfd> creates an unlinked memfd-backed map whose file descriptor can be
passed to another process (via C<SCM_RIGHTS>, C<fork>+C<exec>, or duped+open).
C<new_from_fd> reopens such a descriptor. The descriptor you pass is
duplicated (C<F_DUPFD_CLOEXEC>), so it stays yours to close and closing it
does not disturb the handle. Both require a 64-bit Perl on Linux
(C<memfd_create(2)>).

C<< $map->memfd >> goes the other way: it returns the handle's own descriptor,
not a copy. Pass it, but do not close it: the handle closes it when the map goes
away, and in between the number is reissued to the next file the process opens,
so an early close makes the map's own close hit an unrelated file. Dup it first
if it has to outlive the map.

C<$max_entries>, C<$max_size>, C<$ttl>, C<$lru_skip>, C<$arena_cap>, and
C<$file_mode> are used only when creating a new file; when opening an
existing one, all parameters are read from the stored header and the
constructor arguments are ignored -- but still range-checked, so a value the
module would never accept at creation is rejected either way.

C<$shards> is the exception: a set created by 0.20 or later records its count
in every shard, so opening it with a different one croaks, and an older set
records no count at all. Nothing is ever unlinked, so a refused open leaves
behind the shard files it had to create to notice: treat the count as part of
the path and the files as one unit, and see L</Sharding>. Multiple processes
can open the same file simultaneously. Dies if the file exists but was created
by a different variant or is corrupt.

Optional C<$max_size> enables LRU eviction: when the map reaches C<$max_size>
entries, the least-recently-used entry is evicted on insert. Set to 0 (default)
to disable. LRU uses a clock/second-chance algorithm.

A C<$max_size> at or above the slot count -- 2048 for a map created with 1000,
not the 1536 C<max_entries> reports -- can never drive eviction. The map then
fills up and refuses further inserts, keeping its B<oldest>
keys -- or, with a C<$ttl>, reclaims expired slots for them instead and so keeps
its newest. Every constructor that opens a map for writing warns about this
(category C<misc>), reading the bound off the map rather than its arguments, so
attaching to a sound file never warns however its arguments are written;
silence it with C<no warnings 'misc'>.

Eviction is driven by the entry count, but an exhausted arena evicts too: on a
string variant the arena can run out while the count is still below
C<$max_size>, and rather than refuse the insert the map evicts one entry and
retries the store. Blocks are power-of-two size classes that are never split or
coalesced, so the retry still fails when none of the oldest entries holds a
block of the class the request needs. A request larger than the whole arena is
refused without evicting; one merely larger than every class present is not,
and an insert storing both a string key and a string value can evict for each.
Size C<$arena_cap> for what you actually store, keep the sizes within a few
classes, and check what the insert returned. A map B<without> C<$max_size> has
nothing to evict and still fails the insert. Overwriting a key that is already
there -- C<put> on a hit, C<update>, C<swap>, C<cas> -- stores the new value
before releasing the old one, so on a full arena it evicts the same way, never
the entry it is replacing; without C<$max_size> it fails and leaves the entry
as it was, even when the replacement is the same size as the value it replaces.

Keys and values of 7 bytes or fewer are stored inline and need no arena at all.
A single key or value may be just under 1 GB; longer ones croak.

Optional C<$ttl> sets a default time-to-live in seconds for all entries.
Expired entries are reclaimed lazily, by the next B<mutating> access to that key.
C<remove>, C<update>, C<take>, C<cas>, C<touch>, C<persist> and C<set_ttl> free
the slot; C<incr>, C<add> and C<get_or_set> free it and insert afresh, so the key
is live again when they return; C<put> overwrites it in place. A read --
C<get>, C<exists>, C<get_with_ttl>, C<get_multi>, C<ttl_remaining> -- reports it
absent but leaves it there, so C<size> still counts it. Set to 0 (default) to
disable.

TTLs have whole-second granularity and the deadline is truncated, so an entry
given C<$n> seconds expires somewhere between C<$n-1> and C<$n> seconds later:
a TTL of 1 can expire almost immediately. A refresh that has to beat the TTL
needs more than a second of margin: a heartbeat refreshed every second wants a
TTL of 3, not 2.

Any operation that stores a value resets the entry's TTL to the map default:
C<put>, C<update>, C<cas>, C<incr>/C<decr>/C<incr_by>, C<max>/C<min>,
C<get_or_set> on a hit, and C<set_multi>, as well as the documented C<touch>
and C<swap>. A permanent entry (TTL 0) stays permanent. To carry a per-key TTL
across a value change, write it with C<put_ttl>/C<update_ttl> or restore it
afterwards with C<set_ttl>.

An expired entry keeps its slot until something reclaims it, so C<size> counts
entries that every read reports as absent and that C<keys> and the iterators
skip. An insert that finds no free slot flushes every expired entry at once
rather than failing, so a map whose keys never repeat -- a rate limiter, a
dedup guard -- does not wedge once the table fills. It still carries the dead
weight until then: C<flush_expired> (or C<flush_expired_partial> on a timer)
keeps C<size> honest and the probes short, and C<$max_size> reclaims slots by
eviction as well. Expiry is measured against a monotonic clock
(C<CLOCK_MONOTONIC_COARSE>): TTLs track elapsed running time and do not advance
while the system is suspended or hibernating.

That clock is B<local to the current boot>: it restarts at zero on reboot and is
unrelated between machines, while the expiry timestamps live in the file. A map
that outlives the boot which wrote it -- or is copied to another host, a frozen
map shipped elsewhere included -- therefore carries deadlines on a timeline that
no longer exists: entries live B<longer> than their TTL where the destination's
uptime has not yet reached the stored values, and arrive already expired where
it has, while C<size> still counts them. Nothing crashes, but do not rely on
TTL across a reboot or a host move: C<flush_expired>, C<persist> what you ship,
or rebuild.

Optional C<$lru_skip> (0-99, default 0; 100 or more disables skipping, a
negative value is rejected like any out-of-range size) reduces how often LRU
promotion reorders the recency list -- higher values skip more. Promotion runs
only where an operation updates an existing entry under the write lock
(C<put>/C<incr>/C<get_or_set> on a hit, the update family); C<get>,
C<get_with_ttl> and C<get_multi> never promote, they set the lock-free accessed
bit that clock eviction consumes; C<exists> sets neither, so a key probed only
with C<exists> is evicted as though it had never been read. Skipping cuts
write-lock churn on Zipfian workloads where a few hot keys dominate. The
eviction victim itself is never skipped, so eviction stays correct at any
setting. Set to 0 for strict LRU ordering.

Optional C<$arena_cap> (bytes) sizes the string arena explicitly instead of
deriving it from C<$max_entries>. The default is roughly 128 bytes per entry
(4096 minimum), which a few large strings can exhaust while the table is nearly
empty. Clamped to C<[4096, 0xFFFFFFFF]>; integer-only
variants (C<II>/C<I16>/C<I32>) have none and ignore it; for sharded maps it is
per shard, like C<$max_entries>.

Size it from the rounded lengths, not the byte totals: blocks are powers of two
with a 16-byte minimum, so a 100-byte value takes 128 and a 1100-byte value
2048, and a total can be short by up to half. Blocks are recycled by exact size
class, so a freed large one never serves a smaller request -- a workload
alternating value sizes needs room for one block of each size it uses, not just
the largest.

Optional C<$file_mode> (octal, default C<0600>) sets the permission bits used
when the backing file is created; the exact mode is applied via C<fchmod>, so
the process umask does not narrow it. It is ignored when attaching an existing
file and for anonymous or memfd-backed maps. Pass a wider mode such as C<0666>
to opt in to cross-user sharing. Before version 0.14 the default was C<0666>.

B<Zero-cost when disabled>: with both C<$max_size=0> and C<$ttl=0>, the fast
lock-free read path is used.

=head2 String Keys/Values and UTF-8

String-key variants (C<SS>, C<SI>, C<SI16>, C<SI32>) compare keys as raw
bytes: two keys are the same entry if and only if they contain the same
byte sequence. The SV UTF-8 flag is stored alongside the key so retrieval
round-trips it to the returned SV, but it is B<not> part of key identity.
Consequences:

=over

=item *

ASCII keys with a toggled UTF-8 flag hash and match the same entry
(C<use utf8>, C<utf8::upgrade>, and C<utf8::downgrade> on ASCII are all
equivalent from the map's point of view).

=item *

Non-ASCII keys with different byte encodings are B<distinct>. C<"caf\xe9">
(latin-1, 4 bytes) and the same character sequence under C<use utf8>
(C<"caf\xc3\xa9">, 5 UTF-8 bytes) are two different keys. If your input
comes in mixed encodings, normalize with
C<Encode::encode_utf8> before use.

=back

Two keys that a Perl hash cannot tell apart cannot both survive C<to_hash>.
Perl downgrades a hash key whose characters all fit in a byte, so a stored key
of C<"caf\xc3\xa9"> carrying the UTF-8 flag becomes the hash key C<"caf\xe9">
and lands on top of a stored key of those four bytes. The map holds both, and
C<keys>, C<each> and cursors return both entries; the hashref has one, and
C<keys %$h> is then smaller than C<size>. Normalize the encoding of your keys,
or avoid C<to_hash> when they are mixed.

The stored key keeps the flag it had when the entry was first inserted: a later
C<put> with the same bytes and the opposite flag replaces the value but not the
key, so C<keys> reports the original flag.

String-value variants (C<SS>, C<IS>, C<I16S>, C<I32S>) store the SV UTF-8
flag alongside each value and round-trip it on retrieval. The C<cas>
comparison of C<$expected> against the stored value is byte-only -- the
UTF-8 flag on C<$expected> is ignored.

=head2 Sharding

    my $map = Data::HashMap::Shared::II->new_sharded($path_prefix, $shards, $max_entries, ...);

Creates C<$shards> independent maps (files C<$path_prefix.0>, C<$path_prefix.1>,
...) behind a single handle, each with up to C<$max_entries> entries
(each sized as if it were a map of its own -- see C<max_entries> below for what
the total comes to). Per-key operations automatically
route to the correct shard via hash dispatch. Writes to different shards
proceed in parallel with independent locks. C<new_sharded> requires a
filesystem C<$path_prefix>; anonymous (C<undef>-path) sharded maps are not
supported.

The batch ops (C<set_multi>, C<get_multi>, C<remove_multi>) dispatch each key
to its shard independently, so on a sharded map a batch is B<not> atomic across
shards (the "single lock" note in the API below applies to non-sharded maps).

C<keys>, C<values>, C<items> and C<to_hash> go the other way: they hold every
shard's read lock for the whole call, so they alone see a consistent snapshot
across shards, and a writer to the first shard is blocked until the last shard
has been copied. C<each> takes one shard lock at a time and so blocks a writer
only briefly, but crosses shards unsynchronised.

All operations work transparently on sharded maps: C<put>, C<get>, C<remove>,
C<exists>, C<add>, C<update>, C<swap>, C<take>, C<incr>, C<max>, C<min>,
C<cas>, C<cas_take>, C<get_or_set>, C<put_ttl>, C<add_ttl>, C<update_ttl>,
C<touch>, C<persist>, C<set_ttl>, C<keys>, C<values>, C<items>, C<to_hash>,
C<set_multi> (method only), C<remove_multi> (method only), C<get_multi>
(method only), C<get_with_ttl> (method only), C<each>, C<pop>, C<shift>,
C<drain>, C<clear>, C<flush_expired>, C<flush_expired_partial>, C<size>,
C<stats> (method only), C<reserve>, and all diagnostic keywords.

Diagnostic counters and capacities reported for a sharded handle are
aggregate totals across all shards: C<size>, C<capacity>, C<max_entries>,
C<max_size>, C<tombstones>, C<mmap_size>, C<arena_used>, C<arena_cap>, and the
C<stats> eviction/expiry/recovery counts all sum over the shards. (C<ttl> is
the shared per-entry default, so it reports a single shard's value.)
C<reserve $n> pre-grows B<each> shard to C<$n> entries (not C<$n> in total).

Every shard file must come from the same configuration. Opening a set whose
files disagree -- one left behind by an earlier run with a different C<$ttl> or
C<$max_size> -- croaks, naming the file and the field. Shard 0 is the reference;
C<$max_entries>, C<$max_size>, C<$ttl>, C<$lru_skip>, C<$arena_cap> and the
routing scheme are compared. The shard B<count> is checked separately, against
the C<$shards> you passed: a set written by 0.20 or later records the count it
was created with, so opening it with a different C<$shards> croaks instead of
silently routing to the wrong files. A set written earlier carries no recorded
count: opening one with too few shards is undetected and
silently hides every key that routes elsewhere, while too many is caught only
because the new shards disagree on the routing scheme -- after the first of
them has been created.

Because a missing shard is created fresh, it is created from the arguments this
call passed rather than the ones the set was made with; if they differ the set
is refused, and refused again on every later open with either set of arguments
until the odd shard is removed.

A shard file that goes missing is not detected: the shard is recreated empty and
adopted, so the set silently loses every key that routed to it and C<size> drops
to match, while a process still holding the set open keeps seeing them. Treat
the files as one unit -- copy, move and remove them together. (A set from before
0.20 is refused instead, because the recreated shard disagrees about routing.)

Routing takes the high half of the key's 64-bit hash and slot placement the low
half, so the two never compete for the same bits. Sets created before 0.20
routed on the low half -- the bits the probe also uses -- which lengthened probe
runs as the shard count grew. Which scheme a set uses is recorded in it, so an
existing set keeps working unchanged; it does not gain the shorter probes.
Recreate a set to pick them up. Writes with many shards get faster; reads on
small-table sets with many shards can be a little slower. Use the smallest
shard count that relieves your lock contention, not the largest you can afford.

An earlier release does not refuse a sharded set written by 0.20: the routing
scheme is recorded in a byte it does not read, so it opens the set, routes on
the low half and misses most of the keys -- and if it writes, it stores each of
those keys a second time, in the shard its own scheme picks. C<keys> then lists
the key twice and C<size> counts both, each release reads back only its own
copy, and a C<remove> from one leaves the other behind.

A shard file the earlier release B<creates> is worse: it records the old scheme,
so every open by 0.20 refuses the whole set, naming one offending file at a
time. Removing the named files does not repair the set, whose keys were stored
under both schemes: rebuild it through C<items>, which walks every shard whatever
scheme stored the keys, into a set created by one release. Upgrade every process
that shares a sharded set together, as the crash-safety notes already require,
and create the set with one release before any mixed fleet runs.

C<max_entries> reports the entry count at the table's 75% design load, which is
three quarters of the maximum slot count and so is neither the constructor
argument nor the slot count -- a map created with 1000 reports 1536, over 2048
slots. It is not a hard ceiling either: the table grows to the next power of
two at or above that reported figure, and inserts keep succeeding until every
slot is occupied. Probe length grows sharply over the last few percent, though:
a miss on a table at 99% costs roughly an order of magnitude more than at 95%,
and one on a completely full table has to walk every slot before it can report
absence. Treat C<max_entries> as the size to run at, not the size to reach.

The table shrinks back to fit once removals leave it sparse, undoing any
C<reserve>, so a map that is drained and refilled in cycles regrows through
every doubling on each refill, each one a full rehash. C<reserve> after each
drain avoids it.


Cursors chain across shards automatically. C<cursor_seek> routes to the
correct shard based on key hash. C<$shards> is rounded up to the next
power of 2.

=head2 API

Replace C<xx> with variant prefix: C<i16>, C<i32>, C<ii>, C<i16s>,
C<i32s>, C<is>, C<si16>, C<si32>, C<si>, C<ss>.

    my $ok = shm_xx_put $map, $key, $value;   # insert or overwrite
    my $ok = shm_xx_add $map, $key, $value;   # insert only if key absent
    my $ok = shm_xx_update $map, $key, $value; # overwrite only if key exists
    my $old = shm_xx_swap $map, $key, $value; # put + return old value (undef if new)
    my $ok = shm_xx_cas $map, $key, $expected, $desired; # compare-and-swap
    my $v  = shm_xx_cas_take $map, $key, $expected; # compare-and-remove; returns value on match, undef otherwise
    my $n  = $map->set_multi($k, $v, ...);   # batch put under single lock, returns count
    my $n  = $map->remove_multi(@keys);      # batch remove under single lock, returns count
    my @v  = $map->get_multi($k1, $k2, ...); # batch get under single lock with prefetch pipeline
    my ($v, $ttl) = $map->get_with_ttl($key); # atomic snapshot; () if missing, $ttl is undef on non-TTL map, 0 = permanent; sets LRU clock bit
    my $v  = shm_xx_get $map, $key;           # returns undef if not found
    my $ok = shm_xx_remove $map, $key;        # returns false if not found
    my $ok = shm_xx_exists $map, $key;        # returns boolean
    my $s  = shm_xx_size $map;
    my $m  = shm_xx_max_entries $map;
    my @k  = shm_xx_keys $map;
    my @v  = shm_xx_values $map;
    my @items = shm_xx_items $map;            # flat (k, v, k, v, ...)
    while (my ($k, $v) = shm_xx_each $map) { ... }  # auto-resets at end
    shm_xx_iter_reset $map;
    shm_xx_clear $map;
    my $href = shm_xx_to_hash $map;
    my $v  = shm_xx_get_or_set $map, $key, $default;  # returns value

Several calls below fail for want of room. B<No room> means the table is full
(every slot occupied -- see C<capacity>) or, on a variant with string keys or
values, the arena is.

C<get_or_set> returns the existing value, or stores and returns C<$default> when
the key is absent; C<undef> only when the key is absent and there is no room.

C<cas>, available for all variants, returns true when the stored value matched
C<$expected> and was atomically replaced with C<$desired>; false if the key is
missing or expired, the value did not match, or there is no room. See
L</"String Keys/Values and UTF-8"> for the byte-only comparison rule.

C<swap> returns the previous value, or C<undef> when the key did not exist -- and
B<also> C<undef> when there is no room, in which case an existing key keeps its
old value. It therefore cannot by itself tell a fresh insert from a failure;
check C<exists> or C<size> first if that matters. On a TTL map it refreshes an
existing entry's TTL to the default and assigns the default on insert, leaving a
permanent entry (TTL 0) permanent.

C<get_multi> returns one element per key, in the order asked, with C<undef>
where the key is missing or expired: it never compacts, so the result lines up
with the key list. Like C<get> it sets the LRU accessed bit on a hit and leaves
an expired entry in place for C<size> to count.

Integer-value variants also have:

    my $n = shm_xx_incr $map, $key;           # returns new value
    my $n = shm_xx_decr $map, $key;           # returns new value
    my $n = shm_xx_incr_by $map, $key, $delta;
    my $n = shm_xx_max $map, $key, $desired;  # store max(current, desired), return it
    my $n = shm_xx_min $map, $key, $desired;  # store min(current, desired), return it

A missing key is created starting from zero (Redis-style): the first
C<incr> returns 1, C<decr> returns -1, and C<incr_by> returns C<$delta>.
These die only when the key is new and there is no room for it. The result wraps
at the variant's integer width (see L</"Integer Range and Wrapping">).

C<max>/C<min> atomically store C<max($current, $desired)> /
C<min($current, $desired)> and return the resulting value; a missing key is
inserted as C<$desired>. Against a concurrent C<incr_by>/C<cas>/C<max>/C<min> on
the same key the result is monotonic (C<max> never lowers, C<min> never raises)
and never clobbers a concurrent increment. On a map with LRU or TTL every call
takes the write lock, promotes the entry in the LRU order and refreshes its TTL
even when it stores nothing. Like C<incr_by>, they die only when the key is new
and there is no room for it, and the result wraps at the variant's integer
width.

LRU/TTL operations (C<put_ttl>, C<add_ttl>, and C<update_ttl> require a TTL-enabled map):

    my $ok = shm_xx_put_ttl $map, $key, $value, $ttl_sec;  # per-key TTL (0 = permanent); requires TTL-enabled map
    my $ok = shm_xx_add_ttl $map, $key, $value, $ttl_sec;  # insert-if-absent with per-key TTL (0 = permanent)
    my $ok = shm_xx_update_ttl $map, $key, $value, $ttl_sec; # overwrite-only with per-key TTL (0 = permanent)
    my $ms = shm_xx_max_size $map;            # LRU capacity (0 = disabled)
    my $t  = shm_xx_ttl $map;                 # default TTL in seconds
    my $r  = shm_xx_ttl_remaining $map, $key; # whole seconds left, rounded up (0 = permanent, undef if missing/expired/no TTL)
    my $ok = shm_xx_touch $map, $key;         # refresh TTL to default (permanent entries stay permanent); promotes in LRU; false if no TTL/LRU
    my $ok = shm_xx_persist $map, $key;       # remove TTL, make key permanent; false on non-TTL maps
    my $ok = shm_xx_set_ttl $map, $key, $sec; # change TTL without changing value (0 = permanent); false on non-TTL maps
    my $n  = shm_xx_flush_expired $map;       # proactively expire all stale entries, returns count
    my ($n, $done) = shm_xx_flush_expired_partial $map, $limit;  # gradual: scan $limit slots, minimum 1 ($limit per shard on sharded maps; $done true once every shard completes a cycle)

Atomic remove-and-return:

    my $v = shm_xx_take $map, $key;           # remove key and return value (undef if missing)
    my ($k, $v) = shm_xx_pop $map;            # remove+return from LRU tail / scan forward
    my ($k, $v) = shm_xx_shift $map;          # remove+return from LRU head / scan backward
    my @kv = shm_xx_drain $map, $n;           # remove+return up to N entries as flat (k,v,...) list

C<pop> and C<shift> remove from opposite ends: C<pop> takes the LRU tail
(oldest / least recently used) while C<shift> takes the LRU head (newest /
most recently used). On a sharded map they walk the shards in turn and take
from each shard's own end, so a sequence of C<pop>s is not in global recency
order. On non-LRU maps, C<pop> sweeps the slots forward and C<shift> backward,
each resuming where its last call stopped and wrapping, so successive partial
drains thin the whole table rather than always taking the same end of it.
C<drain> removes in C<pop> order (tail-first). C<pop>, C<shift> and C<drain>
return an empty list on an empty map, so
C<< while (my ($k, $v) = shm_xx_pop $map) >> ends by itself.

Cursors (independent iterators, allow nesting and removal during iteration):

    my $cur = shm_xx_cursor $map;             # create cursor
    while (my ($k, $v) = shm_xx_cursor_next $cur) { ... }
    shm_xx_cursor_reset $cur;                 # restart from beginning
    my $ok = shm_xx_cursor_seek $cur, $key;   # position at key (best-effort across resize); true if found, false if missing/expired
    # cursor auto-destroyed when out of scope
    $cur->next; $cur->reset; $cur->seek($key);   # method forms

C<shm_xx_each> is also safe to use with C<remove> during iteration.

A C<cursor_seek> that returns false leaves the cursor where it was: it neither
repositions a sharded pass nor rewinds a cursor that has run out.

Leaving an C<each> loop early -- C<last>, C<return>, an exception -- leaves the
built-in iterator open on that handle, and tombstone compaction and shrink stay
deferred for as long as it is: a long-lived handle that keeps removing and
re-inserting keys then grows its table instead of compacting it, all the way to
its maximum slot count. Removals on their own leave tombstones without growing it.
Unlike Perl's C<each>, C<keys> does B<not> reset it. Call C<iter_reset> when you
abandon a pass, or run it to completion. The deferral is also per handle, not per
map, so another process can compact or shrink the table underneath your
iteration; that restarts it, and an abandoned pass can then yield keys it has
already returned.
Tombstone compaction and shrink are deferred until iteration ends. Growth is
not -- a load-driven insert still resizes -- and neither is compaction once the
table has reached its maximum capacity and its load (live entries plus
tombstones) has passed 75% of the slots: an insert during an iteration can
restart it there too, and keys already visited are visited again.
On a sharded map a cursor restarts only
within the shard it has reached, so shards it already passed are not revisited;
take a fresh cursor after a C<clear> if you need a complete pass.

Diagnostics:

    my $cap = shm_xx_capacity $map;           # current table capacity (slots)
    my $tb  = shm_xx_tombstones $map;         # tombstone count
    my $au  = shm_xx_arena_used $map;         # arena high-water mark (0 for int-only)
    my $ac  = shm_xx_arena_cap $map;          # arena total capacity (0 for int-only)
    my $sz  = shm_xx_mmap_size $map;          # backing file size in bytes
    my $ok  = shm_xx_reserve $map, $n;        # pre-grow (false if exceeds max)
    my $ev  = shm_xx_stat_evictions $map;     # cumulative LRU eviction count
    my $ex  = shm_xx_stat_expired $map;       # cumulative TTL expiration count
    my $rc  = shm_xx_stat_recoveries $map;    # cumulative stale lock recovery count
    my $p   = $map->path;                    # backing file path (method only)
    my $s   = $map->stats;                   # hashref with all diagnostics in one call (not an atomic snapshot)
    # stats keys: size, capacity, max_entries, tombstones, mmap_size,
    #   arena_used, arena_cap, evictions, expired, recoveries, max_size, ttl,
    #   frozen, readonly

An eviction whose victim has already expired counts as an expiration, not an
eviction, so a TTL cache under capacity pressure reports fewer evictions than
the inserts that displaced an entry.

C<set_multi>, C<get_multi>, C<remove_multi>, C<get_with_ttl>, C<stats>,
C<path>, C<sync>, C<unlink>, C<freeze>, C<frozen>, C<readonly> and C<memfd> are
method-only (no keyword form).

Keywords take their arguments as a list, so a keyword that takes more than one
argument must be written without parentheses around them:

    shm_ii_put $map, $key, $value;            # correct
    shm_ii_put($map, $key, $value);           # error, usually at compile time

A single-argument keyword accepts either form.  The method call
C<< $map->put($key, $value) >> is always available if you prefer parentheses.

C<keys>, C<values>, C<items>, C<each>, C<get_multi>, C<get_with_ttl>, C<pop>,
C<shift>, C<drain>, C<flush_expired_partial> and the cursor's C<next> return
lists. Like any Perl sub returning a list, in scalar context they yield their
B<last> element -- not a count, and not the first -- so call them in list
context and use C<size> when you want a count.

Calling C<no Data::HashMap::Shared::II;> disables that variant's keywords for
the rest of the enclosing lexical scope.

File management:

    $map->sync;                               # flush the mmap to the backing file (msync MS_SYNC)
    $map->unlink;                             # remove backing file (mmap stays valid)
    Data::HashMap::Shared::II->unlink($path); # class method form (single file)

C<sync> issues a synchronous C<msync(2)> over the whole mapping (every
shard, for sharded maps) and dies on error. Use it to force durability of
a file-backed map; it is a no-op for anonymous mappings, which have no
backing file. Changes are visible to other processes sharing the mapping
without C<sync> -- it only affects on-disk persistence.

C<unlink> reports through its return value rather than by dying: it returns
true when the file (every shard, for sharded maps) was removed and false
otherwise, including when the file was already gone and when removal was
refused -- a read-only directory, for instance. Check it if the removal
mattered.

=head2 Frozen (Read-Only) Mode

    $map->freeze;                                       # seal the file immutable (durable)
    my $ro = Data::HashMap::Shared::II->new_readonly($path);
    my $v  = $ro->get($key);                            # lock-free query; writes nothing
    my $is_frozen   = $map->frozen;                     # true once sealed
    my $is_readonly = $ro->readonly;                    # true for a read-only handle

C<freeze> permanently seals a map's contents so it can be shipped and served
read-only (it works on anonymous and memfd maps too, though only a file can be
shipped). It takes the write lock and flushes the sealed header to disk, so the
seal is durable. Afterwards every mutator on that
handle croaks and the handle itself becomes read-only. A sharded map seals every
shard file. Freezing is one-way; there is no unfreeze.

B<Quiesce your writers first.> A mutator tests the seal on entry and takes the
write lock afterwards, so another process already inside a mutating call when
C<freeze> runs completes its write after the seal: the sealed file changes once
more, and a C<new_readonly> reader can observe it. Seal a map only when nothing
else is writing to it; C<freeze> cannot detect a writer that has passed the
check but not yet reached the lock.

On a sharded map this is not one straggling write. Whole-map and batch
operations -- C<set_multi>, C<remove_multi>, C<clear>, C<drain>, C<pop>,
C<shift>, C<flush_expired>, C<flush_expired_partial>, C<reserve> -- test the seal
once and then take each shard's lock in turn, so one that is under way when
C<freeze> lands keeps writing for the whole remainder of the call, across every
shard it has not reached yet.

C<new_readonly> opens an already-frozen file with C<O_RDONLY> and maps it
C<PROT_READ>. Queries take B<no lock at all> -- no reader-slot bookkeeping, no
LRU clock bit, no lazy TTL cleanup -- and never write the mapping, so a
read-only view works from a read-only file or filesystem, and any number of
processes can share one frozen file at once. All queries and full iteration are
supported: C<get>, C<exists>, C<get_with_ttl>, C<get_multi>, C<keys>,
C<values>, C<items>, C<to_hash>, C<each>, and cursors (C<cursor>,
C<cursor_next>, C<cursor_reset> and C<cursor_seek>). Every mutator croaks,
including the integer counters C<incr>/C<decr>/C<max>/C<min>. C<sync> is a
silent no-op. C<frozen> and C<readonly> report the state, and C<stats> gains
matching C<frozen> and C<readonly> keys.

The on-disk format and version are unchanged by the seal: a file written by an
older release is simply not frozen and opens read-write exactly as before.

The two modes never mix: opening a frozen file read-write (C<new>,
C<new_from_fd>) is refused -- open it with C<new_readonly> instead -- and
C<new_readonly> refuses a file that has not been frozen.

C<new_readonly> is for a single backing file, and there is no read-only sharded
constructor, so C<freeze> on a sharded map seals a set that no constructor will
reopen: C<new_sharded> refuses the frozen shards, and reading it back means
opening each shard file by name and probing them. Freeze single-file maps.

B<Portability>: a frozen file is a raw memory image. Read it back on the B<same
architecture> that wrote it (same word size and endianness; the native magic and
variant id reject a mismatched or wrong-variant file at attach time). Ship it by
B<copying> the file; do not serve it over NFS or another network filesystem
while another host has it mapped.

=head2 Crash Safety

If a process dies (e.g., SIGKILL, OOM kill) while holding the write lock,
other processes detect the stale lock within 2 seconds and automatically
recover.

Reader-side recovery uses a 1024-slot table in the shared mmap (one slot
per B<handle>, claimed lazily on first lock -- a process holding several
handles on one map uses a slot for each; fork()'d children claim a
fresh slot via C<pthread_atfork>).  A dead reader is neutralised by a
draining writer, which clears its slot as it scans, so a worker killed
mid-C<incr_by> cannot pin the lock.  Beyond 1024
simultaneous handles per map, a handle that cannot claim a slot proceeds
"slotless"; see L</"Reader-slot exhaustion"> for the one case that
recovery cannot cover.

The same path validates and rebuilds the LRU doubly-linked list if a
dead writer left it inconsistent.  C<stat_recoveries> in C<stats> counts stale
B<write>-lock recoveries; a dead reader drained by a writer is not counted, so
the counter staying at zero does not mean nothing has been recovered.

Recovery uses C<kill($pid, 0)> for liveness, which cannot tell a reused PID from
the original -- and the lock word lives in the file, so it lasts as long as the
file does. Within one running system the risk is small: the holder must die in
the window it holds the lock B<and> the kernel must reissue that exact PID to a
long-lived process before the next waiter looks.

It is B<not> small once the file outlives the PID space that wrote it. A reboot,
a container restart against a persisted volume, or a copy taken while a writer
held the lock leaves a lock word naming a PID the new system may already have
reissued. If it went to a long-lived process, every writer
waits on a holder that will never release, unbounded and silent: no error, no
warning, no timeout; readers wait too when the crash was mid-publish. Nothing in
the API can break such a lock -- the file has to be recreated. A killed B<reader>
strands its slot the same way, since that records a PID too, and the read lock
is held by C<each>, C<keys>, C<values>, C<items> and, without LRU or TTL, by
C<incr>, C<max> and C<min>. So carry a map across a reboot or a container
restart only if every process that used it exited cleanly, and copy one only
while nothing is using it.

B<Limitation>: PID-based recovery assumes all processes share the same
PID namespace. Cross-container sharing (different PID namespaces) is not
supported.

B<A full filesystem arrives as SIGBUS, not as an error.> The backing file is
sized once, at creation, for the map's maximum geometry, and its table and arena
are otherwise sparse: growing the table writes into pages that were never
allocated rather than extending the file. So C<mmap_size> is the space the file
will need once every page has been touched, not what it occupies now, and
if the filesystem fills while a page is first written, the kernel raises SIGBUS
in the writing process instead of returning an error. One raised in the middle
of a table resize takes with it the entries not yet re-inserted, exactly as a
SIGKILL there would. Leave C<mmap_size> bytes of headroom on the filesystem, or
C<fallocate -l> the file after creating it to take the allocation failure up
front rather than at an arbitrary later insert. Use B<exactly> C<mmap_size>
bytes: a file longer than the size recorded in its header is refused as corrupt,
and for a sharded set C<mmap_size> is the total across shards, so use each shard
file's own size rather than the aggregate.

After recovery from a mid-mutation crash, the map data may be partially
inconsistent (e.g., one entry was being updated when the writer died).
Locks, the LRU chain and the entry counters are restored. The arena free
lists are not rebuilt, so blocks in flight at the crash may leak; the specific
entry being mutated may have stale or partial bytes; and a crash part-way
through a table resize permanently drops the entries that had not yet been
re-inserted. Calling C<clear> after detecting a stale lock recovery is
recommended for safety-critical applications.

An interrupted B<create> is recovered too. A creator killed after the file is
sized but before its header is committed leaves a full-size, all-zero file,
which C<new> re-initializes -- but only when the file is exactly the size the
requested geometry needs, is owned by your effective uid, and is still entirely
zero. A file holding data is never re-initialized. Once the first header field
has landed the file can no longer be told from a corrupt one, and C<new> croaks
with C<incomplete map file left by an interrupted create; remove it and retry>.
An abandoned create never held data, so removing it is safe -- but a header
corrupted after the fact reaches the same croak, so check before deleting
anything you care about.

Recovery is run by whichever process next takes a lock, readers included, so a
map shared with a process running anything older than 0.18 keeps that release's
crash windows. Upgrade every process sharing a map together.

=head2 Reader-slot exhaustion

A reader that cannot claim a slot in the table described under
L</"Crash Safety"> proceeds "slotless": it still takes the read lock but leaves
no per-process record, so if it is killed while holding the lock its share
cannot be attributed to a dead process. Writer recovery cannot reclaim it and
writers may block until the mapping is recreated. Reaching this needs more than
1024 handles open on one mapping at once plus a crash in the brief read-lock
window, so in practice it is very unlikely.

=head1 BENCHMARKS

Throughput versus other shared-memory / on-disk solutions, 25K entries,
single process, Linux x86_64.  Each benchmarked sub runs over all 25,000
entries, so the figures below are C<Benchmark> rates -- whole passes per second,
higher is better -- and not operations per second.  Multiply by 25,000 for the
rate of the operation named: C<Shared::II> LOOKUP at 353 is about 8.8 M
lookups/s.  (A pass can do more than the operation it is named for: DELETE
refills the map first.)  The cross-process table further down is already in
operations per second.  Run C<perl -Mblib bench/vs.pl 25000> to reproduce.

B<Integer key -> integer value> (Shared::II):

              BerkeleyDB   LMDB   Shared::II
    INSERT          30       44         280
    LOOKUP          38       38         353
    INCREMENT       16       17         247

B<String key -> string value, short> (inline <= 7B, Shared::SS):

              FastMmap   BerkeleyDB   LMDB   SharedMem   Shared::SS
    INSERT        17          30       43        64          189
    LOOKUP        15          35       36       154          220
    DELETE        --          15       19        34          101

B<String key -> string value, long> (~50-100B, Shared::SS):

              BerkeleyDB   LMDB   SharedMem   Shared::SS
    INSERT        26         40        63          196
    LOOKUP        34         35       136          248

B<LRU cache lookup> (25K entries, lock-free clock eviction):

              plain   LRU
    II         342    327   (lock-free; within run-to-run noise of plain)
    SS         165    164

B<Cross-process> (25K SS entries, 2 processes, ops/s):

                  Shared::SS   SharedMem       LMDB
    READS        3,798,000    3,085,000     854,000
    WRITES       2,424,000      984,000     130,000
    MIXED 50/50  5,738,000    2,470,000     275,000

LMDB benchmarked with MDB_WRITEMAP|MDB_NOSYNC|MDB_NOMETASYNC|MDB_NORDAHEAD.
BerkeleyDB with DB_PRIVATE|128MB cache.

Key takeaways:

=over

=item * B<9x> faster lookups than LMDB for integer keys (lock-free seqlock path)

=item * B<1.4x> faster than Hash::SharedMem for short string lookups (inline strings, no arena overhead)

=item * B<1.8x> faster than Hash::SharedMem for long string lookups

=item * B<4.4x> faster cross-process reads than LMDB; B<2.5x> faster writes than SharedMem

=item * LRU reads are lock-free (clock eviction) -- no overhead vs plain maps

=item * Atomic C<incr> is B<14x> faster than get+put on competitors

=item * Strings <= 7 bytes stored inline in node (zero arena overhead)

=back

=head1 SEE ALSO

L<Data::HashMap::Shared::Cookbook> - recipes for counters, caches, rate limits,
liveness, dedup and atomic state

L<Data::Buffer::Shared> - typed shared array

L<Data::Queue::Shared> - FIFO queue

L<Data::PubSub::Shared> - publish-subscribe ring

L<Data::ReqRep::Shared> - request-reply

L<Data::Sync::Shared> - synchronization primitives

L<Data::Pool::Shared> - fixed-size object pool

L<Data::Stack::Shared> - LIFO stack

L<Data::Deque::Shared> - double-ended queue

L<Data::Log::Shared> - append-only log (WAL)

L<Data::Heap::Shared> - priority queue

L<Data::Graph::Shared> - directed weighted graph

L<Data::BitSet::Shared> - shared bitset (lock-free per-bit ops)

L<Data::RingBuffer::Shared> - fixed-size overwriting ring buffer

=head1 SECURITY

Backing files are created with mode C<0600> (owner-only) by default, so only
the creating user can open and attach them. To share a backing file across
users, pass an explicit octal file mode such as C<0660> as the last argument
to C<new>; the mode is applied when the file is created, and when a file left
behind by an interrupted create is re-initialized (see L</"Crash Safety">); a
file already in use keeps its own permissions. The file is opened with
C<O_NOFOLLOW>, so a symlink planted at the path is refused, and created with
C<O_EXCL>; the on-disk header is validated when the file is attached. Any
process you grant write access to a shared mapping is trusted not to corrupt
its contents while other processes are using it.

Header validation does not extend to the entries themselves. A string offset or
length that falls outside the arena yields an empty string, a zeroed value or no
match rather than a read past the mapping, on the write-locked paths as much as
on the lock-free reads. Only those arena bounds are enforced. The rest of a
map's per-slot data -- the LRU links above all -- is trusted, so behaviour on a
corrupted file is undefined: it may return wrong answers, crash, or write
outside the mapping. Corruption is out of the threat model, not defended
against.

A backing file written before 0.16 uses the previous on-disk format and is
rejected with a version-mismatch error when attached; recreate the map from
its source data. Anonymous and memfd maps are process-local and unaffected.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

It bundles xxHash by Yann Collet, used under the BSD 2-Clause licence; see
F<LICENSE.xxhash> in the distribution.

=cut
