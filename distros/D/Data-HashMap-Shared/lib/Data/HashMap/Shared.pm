package Data::HashMap::Shared;
use strict;
use warnings;
our $VERSION = '0.10';

require XSLoader;
XSLoader::load('Data::HashMap::Shared', $VERSION);

1;

__END__

=encoding utf-8

=head1 NAME

Data::HashMap::Shared - Type-specialized shared-memory hash maps for multiprocess access

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

    # Atomic counters (lock-free fast path)
    shm_ii_incr $map, 1;
    shm_ii_incr_by $map, 1, 10;

    # Compare-and-swap (all variants; byte-compare for string values)
    shm_ii_cas $map, 1, 11, 42;     # swap to 42 only if current == 11

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
multiprocess data sharing on Linux.

B<Linux-only>. Requires 64-bit Perl.

=head2 Features

=over

=item * File-backed mmap for cross-process sharing

=item * Futex-based read-write lock (fast userspace path)

=item * Lock-free atomic counters (incr/decr under read lock)

=item * Elastic capacity (starts small, grows/shrinks automatically)

=item * Arena allocator for string storage in shared memory

=item * Keyword API via XS::Parse::Keyword for maximum speed

=item * Opt-in LRU eviction and per-key TTL (lock-free reads via clock eviction)

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
    my $map = Data::HashMap::Shared::II->new_memfd($name, $max_entries, ...); # memfd-backed
    my $map = Data::HashMap::Shared::II->new_from_fd($fd);            # reopen memfd
    my $fd  = $map->memfd;                                            # -1 if not memfd

Creates or opens a shared hash map backed by file C<$path>. Passing C<undef>
as the path creates an anonymous C<MAP_SHARED|MAP_ANONYMOUS> mapping that is
inherited across C<fork> but has no filesystem presence.

C<new_memfd> creates an unlinked memfd-backed map whose file descriptor
can be passed to another process (via C<SCM_RIGHTS>, C<fork>+C<exec>, or
duped+open). C<new_from_fd> reopens such a descriptor. Both require a
64-bit Perl on Linux (C<memfd_create(2)>).
C<$max_entries>, C<$max_size>, C<$ttl>, and C<$lru_skip> are used only when
creating a new file; when opening an existing one, all parameters are read
from the stored header and the constructor arguments are ignored.
Multiple processes can open the same file simultaneously.
Dies if the file exists but was created by a different variant or is corrupt.

Optional C<$max_size> enables LRU eviction: when the map reaches C<$max_size>
entries, the least-recently-used entry is evicted on insert. Set to 0 (default)
to disable. LRU uses a clock/second-chance algorithm: C<get> sets an accessed
bit (lock-free, no write lock), and eviction gives a second chance to recently
accessed entries before evicting.

Optional C<$ttl> sets a default time-to-live in seconds for all entries.
Expired entries are lazily removed on access. Set to 0 (default) to disable.
When TTL is active, C<get> and C<exists> check expiry.

Optional C<$lru_skip> (0-99, default 0) sets the probability (as a percentage)
of skipping LRU promotion on C<get>. This reduces write-lock contention for
Zipfian (power-law) access patterns where a small set of hot keys dominates
reads. The LRU tail (eviction victim) is never skipped, preserving eviction
correctness. Set to 0 for strict LRU ordering.

B<Zero-cost when disabled>: with both C<$max_size=0> and C<$ttl=0>, the fast
lock-free read path is used. The only overhead is a branch (predicted away).

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
(latin-1, 4 bytes) and C<"café"> with C<use utf8> (5 UTF-8 bytes) are two
different keys. If your input comes in mixed encodings, normalize with
C<Encode::encode_utf8> before use.

=back

String-value variants (C<SS>, C<IS>, C<I16S>, C<I32S>) store the SV UTF-8
flag alongside each value and round-trip it on retrieval. The C<cas>
comparison of C<$expected> against the stored value is byte-only — the
UTF-8 flag on C<$expected> is ignored (same rationale as string-key
equality).

=head2 Sharding

    my $map = Data::HashMap::Shared::II->new_sharded($path_prefix, $shards, $max_entries, ...);

Creates C<$shards> independent maps (files C<$path_prefix.0>, C<$path_prefix.1>,
...) behind a single handle, each with up to C<$max_entries> entries
(total capacity is C<$shards * $max_entries>). Per-key operations automatically
route to the correct shard via hash dispatch. Writes to different shards
proceed in parallel with independent locks.

All operations work transparently on sharded maps: C<put>, C<get>, C<remove>,
C<exists>, C<add>, C<update>, C<swap>, C<take>, C<incr>, C<cas>, C<cas_take>,
C<get_or_set>, C<put_ttl>, C<add_ttl>, C<update_ttl>, C<touch>, C<persist>,
C<set_ttl>, C<keys>, C<values>, C<items>, C<to_hash>, C<set_multi> (method only),
C<remove_multi> (method only), C<get_multi> (method only),
C<get_with_ttl> (method only), C<each>, C<pop>, C<shift>, C<drain>,
C<clear>, C<flush_expired>, C<flush_expired_partial>, C<size>,
C<stats> (method only), C<reserve>, and all diagnostic keywords.

Cursors chain across shards automatically. C<cursor_seek> routes to the
correct shard based on key hash. C<$shards> is rounded up to the next
power of 2.

=head2 API

Replace C<xx> with variant prefix: C<i16>, C<i32>, C<ii>, C<i16s>,
C<i32s>, C<is>, C<si16>, C<si32>, C<si>, C<ss>.

    my $ok = shm_xx_put $map, $key, $value;   # insert or overwrite
    my $ok = shm_xx_add $map, $key, $value;   # insert only if key absent
    my $ok = shm_xx_update $map, $key, $value; # overwrite only if key exists
    my $old = shm_xx_swap $map, $key, $value; # put + return old value (undef if new); on TTL maps, refreshes TTL for keys that already had one and assigns default_ttl on insert (permanent entries stay permanent)
    my $ok = shm_xx_cas $map, $key, $expected, $desired; # compare-and-swap
    my $v  = shm_xx_cas_take $map, $key, $expected; # compare-and-remove; returns value on match, undef otherwise
    my $n  = $map->set_multi($k, $v, ...);   # batch put under single lock, returns count
    my $n  = $map->remove_multi(@keys);      # batch remove under single lock, returns count
    my @v  = $map->get_multi($k1, $k2, ...); # batch get under single lock with prefetch pipeline
    my ($v, $ttl) = $map->get_with_ttl($key); # atomic snapshot; () if missing, $ttl is undef on non-TTL map, 0 = permanent; does not promote in LRU
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

C<cas> is available for all variants. Returns true when the stored value
matched C<$expected> and was atomically replaced with C<$desired>; false
if the key is missing or expired, the value did not match, or (string-value
variants) the arena is full. See L</"String Keys/Values and UTF-8"> for
the byte-only comparison rule.

C<swap> returns the previous value, or C<undef> when the key did not exist
(a fresh insert). C<undef> is B<also> returned when the new value cannot be
stored — the map is already at C<max_entries> capacity, or (string-value
variants) the arena is full — in which case an existing key keeps its old
value. C<swap> by itself therefore cannot distinguish a fresh insert from a
full-map failure; check C<exists> or C<size> first if that matters.

Integer-value variants also have:

    my $n = shm_xx_incr $map, $key;           # returns new value
    my $n = shm_xx_decr $map, $key;           # returns new value
    my $n = shm_xx_incr_by $map, $key, $delta;

A missing key is created starting from zero (Redis-style): the first
C<incr> returns 1, C<decr> returns -1, and C<incr_by> returns C<$delta>.
These die only when the key is new and the map is already at
C<max_entries> (no room to insert). The result wraps at the variant's
integer width (see L</"Integer Range and Wrapping">).

LRU/TTL operations (C<put_ttl>, C<add_ttl>, and C<update_ttl> require a TTL-enabled map):

    my $ok = shm_xx_put_ttl $map, $key, $value, $ttl_sec;  # per-key TTL (0 = permanent); requires TTL-enabled map
    my $ok = shm_xx_add_ttl $map, $key, $value, $ttl_sec;  # insert-if-absent with per-key TTL (0 = permanent)
    my $ok = shm_xx_update_ttl $map, $key, $value, $ttl_sec; # overwrite-only with per-key TTL (0 = permanent)
    my $ms = shm_xx_max_size $map;            # LRU capacity (0 = disabled)
    my $t  = shm_xx_ttl $map;                 # default TTL in seconds
    my $r  = shm_xx_ttl_remaining $map, $key; # seconds left (0 = permanent, undef if missing/expired/no TTL)
    my $ok = shm_xx_touch $map, $key;         # reset TTL to default; promotes in LRU; false if no TTL/LRU
    my $ok = shm_xx_persist $map, $key;       # remove TTL, make key permanent; false on non-TTL maps
    my $ok = shm_xx_set_ttl $map, $key, $sec; # change TTL without changing value (0 = permanent); false on non-TTL maps
    my $n  = shm_xx_flush_expired $map;       # proactively expire all stale entries, returns count
    my ($n, $done) = shm_xx_flush_expired_partial $map, $limit;  # gradual: scan $limit slots

Atomic remove-and-return:

    my $v = shm_xx_take $map, $key;           # remove key and return value (undef if missing)
    my ($k, $v) = shm_xx_pop $map;            # remove+return from LRU tail / scan forward
    my ($k, $v) = shm_xx_shift $map;          # remove+return from LRU head / scan backward
    my @kv = shm_xx_drain $map, $n;           # remove+return up to N entries as flat (k,v,...) list

C<pop> and C<shift> remove from opposite ends: C<pop> takes the LRU tail
(oldest / least recently used) while C<shift> takes the LRU head (newest /
most recently used). On non-LRU maps, C<pop> scans forward and C<shift>
scans backward. C<drain> removes in C<pop> order (tail-first).
Useful for work-queue patterns and batch processing.

Cursors (independent iterators, allow nesting and removal during iteration):

    my $cur = shm_xx_cursor $map;             # create cursor
    while (my ($k, $v) = shm_xx_cursor_next $cur) { ... }
    shm_xx_cursor_reset $cur;                 # restart from beginning
    shm_xx_cursor_seek $cur, $key;            # position at specific key (best-effort across resize)
    # cursor auto-destroyed when out of scope

C<shm_xx_each> is also safe to use with C<remove> during iteration.
Resize/compaction is deferred until iteration ends.

Diagnostics:

    my $cap = shm_xx_capacity $map;           # current table capacity (slots)
    my $tb  = shm_xx_tombstones $map;         # tombstone count
    my $au  = shm_xx_arena_used $map;         # arena bytes used (0 for int-only)
    my $ac  = shm_xx_arena_cap $map;          # arena total capacity (0 for int-only)
    my $sz  = shm_xx_mmap_size $map;          # backing file size in bytes
    my $ok  = shm_xx_reserve $map, $n;          # pre-grow (false if exceeds max)
    my $ev  = shm_xx_stat_evictions $map;     # cumulative LRU eviction count
    my $ex  = shm_xx_stat_expired $map;       # cumulative TTL expiration count
    my $rc  = shm_xx_stat_recoveries $map;    # cumulative stale lock recovery count
    my $p   = $map->path;                    # backing file path (method only)
    my $s   = $map->stats;                   # hashref with all diagnostics in one call
    # stats keys: size, capacity, max_entries, tombstones, mmap_size,
    #   arena_used, arena_cap, evictions, expired, recoveries, max_size, ttl

C<set_multi>, C<get_multi>, C<remove_multi>, C<get_with_ttl>, C<stats>,
C<path>, C<sync>, and C<unlink> are method-only (no keyword form).

File management:

    $map->sync;                               # flush the mmap to the backing file (msync MS_SYNC)
    $map->unlink;                             # remove backing file (mmap stays valid)
    Data::HashMap::Shared::II->unlink($path); # class method form

C<sync> issues a synchronous C<msync(2)> over the whole mapping (every
shard, for sharded maps) and dies on error. Use it to force durability of
a file-backed map; it is a no-op for anonymous mappings, which have no
backing file. Changes are visible to other processes sharing the mapping
without C<sync> — it only affects on-disk persistence.

=head2 Crash Safety

If a process dies (e.g., SIGKILL, OOM kill) while holding the write lock,
other processes detect the stale lock within 2 seconds and automatically
recover. The writer's PID is encoded in the rwlock word itself (single
atomic CAS, no crash window). On C<FUTEX_WAIT> timeout, waiters
C<kill($pid, 0)> the holder and CAS-release the lock if it's dead.

Reader-side recovery uses a 1024-slot table in the shared mmap (one slot
per process, claimed lazily on first lock; fork()'d children claim a
fresh slot via C<pthread_atfork>).  On a writer-lock timeout the recovery
scan CAS-claims each dead PID's slot, drains the waiter counts, and
force-resets the reader counter once no live reader holds it — so a
worker killed mid-C<incr_by> no longer pins the rwlock indefinitely.
If a live reader is concurrently present, the dead slot is left intact
for the next recovery cycle (preserves the only record of the stuck
counter).  Beyond 1024 simultaneous handles per map, new handles skip
slot tracking and fall back to the slow per-timeout drain.

The same path validates and rebuilds the LRU doubly-linked list if a
dead writer left it inconsistent.  C<stat_recoveries> in C<stats> counts
every recovery event.

B<Limitation>: PID-based recovery assumes all processes share the same
PID namespace. Cross-container sharing (different PID namespaces) is not
supported.

After recovery from a mid-mutation crash, the map data may be partially
inconsistent (e.g., one entry was being updated when the writer died).
Map structure (locks, LRU, free lists, counters) is restored, but the
specific entry being mutated may have stale or partial bytes. Calling
C<clear> after detecting a stale lock recovery is recommended for
safety-critical applications.

=head1 BENCHMARKS

Throughput versus other shared-memory / on-disk solutions, 25K entries,
single process, Linux x86_64.  All values in M ops/s (higher is better).
Run C<perl -Mblib bench/vs.pl 25000> to reproduce.

B<Integer key E<rarr> integer value> (Shared::II):

              BerkeleyDB   LMDB   Shared::II
    INSERT          31       46         184
    LOOKUP          35       40         383
    INCREMENT       16       18         165

B<String key E<rarr> string value, short> (inline E<le> 7B, Shared::SS):

              FastMmap   BerkeleyDB   LMDB   SharedMem   Shared::SS
    INSERT        11          26       40        62          130
    LOOKUP        10          32       34       146          213
    DELETE        14          18       --        32           68

B<String key E<rarr> string value, long> (~50-100B, Shared::SS):

              BerkeleyDB   LMDB   SharedMem   Shared::SS
    INSERT        25         37        61          133
    LOOKUP        30         33       125          229

B<LRU cache lookup> (25K entries, lock-free clock eviction):

              plain   LRU
    II         350    373   (lock-free, ~6% faster via clock)
    SS         159    159

B<Cross-process> (25K SS entries, 2 processes, ops/s):

                  Shared::SS   SharedMem       LMDB
    READS        3,250,000    1,986,000     728,000
    WRITES       2,801,000      826,000      95,000
    MIXED 50/50  3,691,000    1,963,000     211,000

LMDB benchmarked with MDB_WRITEMAP|MDB_NOSYNC|MDB_NOMETASYNC|MDB_NORDAHEAD.
BerkeleyDB with DB_PRIVATE|128MB cache.

Key takeaways:

=over

=item * B<10x> faster lookups than LMDB for integer keys (lock-free seqlock path)

=item * B<1.5x> faster than Hash::SharedMem for short string lookups (inline strings, no arena overhead)

=item * B<1.8x> faster than Hash::SharedMem for long string lookups

=item * B<4.5x> faster cross-process reads than LMDB; B<3.4x> faster writes than SharedMem

=item * LRU reads are lock-free (clock eviction) — no overhead vs plain maps

=item * Atomic C<incr> is B<9x> faster than get+put on competitors

=item * Strings E<le> 7 bytes stored inline in node (zero arena overhead)

=back

=head1 SEE ALSO

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

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
