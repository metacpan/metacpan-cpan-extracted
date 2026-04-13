package Data::HashMap::Shared;
use strict;
use warnings;
our $VERSION = '0.05';

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

=item * Stale lock recovery (automatic detection of dead lock holders via PID tracking)

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

=head2 Constructor

    my $map = Data::HashMap::Shared::II->new($path, $max_entries);
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size);
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size, $ttl);
    my $map = Data::HashMap::Shared::II->new($path, $max_entries, $max_size, $ttl, $lru_skip);

Creates or opens a shared hash map backed by file C<$path>.
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

=head2 Sharding

    my $map = Data::HashMap::Shared::II->new_sharded($path_prefix, $shards, $max_entries, ...);

Creates C<$shards> independent maps (files C<$path_prefix.0>, C<$path_prefix.1>,
...) behind a single handle. Per-key operations automatically route to the
correct shard via hash dispatch. Writes to different shards proceed in parallel
with independent locks.

All operations work transparently on sharded maps: C<put>, C<get>, C<remove>,
C<exists>, C<add>, C<update>, C<swap>, C<take>, C<incr>, C<cas>,
C<get_or_set>, C<put_ttl>, C<touch>, C<persist>, C<set_ttl>, C<keys>,
C<values>, C<items>, C<to_hash>, C<set_multi> (method only),
C<get_multi> (method only), C<each>,
C<pop>, C<shift>, C<drain>, C<clear>, C<flush_expired>,
C<flush_expired_partial>, C<size>, C<stats> (method only), C<reserve>,
and all diagnostic keywords.

Cursors chain across shards automatically. C<cursor_seek> routes to the
correct shard based on key hash. C<$shards> is rounded up to the next
power of 2.

=head2 API

Replace C<xx> with variant prefix: C<i16>, C<i32>, C<ii>, C<i16s>,
C<i32s>, C<is>, C<si16>, C<si32>, C<si>, C<ss>.

    my $ok = shm_xx_put $map, $key, $value;   # insert or overwrite
    my $ok = shm_xx_add $map, $key, $value;   # insert only if key absent
    my $ok = shm_xx_update $map, $key, $value;# overwrite only if key exists
    my $old = shm_xx_swap $map, $key, $value; # put + return old value (undef if new)
    my $n  = $map->set_multi($k, $v, ...);   # batch put under single lock, returns count
    my @v  = $map->get_multi($k1, $k2, ...); # batch get under single lock with prefetch pipeline
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

Integer-value variants also have:

    my $n = shm_xx_incr $map, $key;           # returns new value
    my $n = shm_xx_decr $map, $key;           # returns new value
    my $ok = shm_xx_cas $map, $key, $expected, $desired; # compare-and-swap
    my $n = shm_xx_incr_by $map, $key, $delta;

LRU/TTL operations (require TTL-enabled map for C<put_ttl>):

    my $ok = shm_xx_put_ttl $map, $key, $value, $ttl_sec;  # per-key TTL (0 = permanent); requires TTL-enabled map
    my $ms = shm_xx_max_size $map;            # LRU capacity (0 = disabled)
    my $t  = shm_xx_ttl $map;                 # default TTL in seconds
    my $r  = shm_xx_ttl_remaining $map, $key; # seconds left (0 = permanent, undef if missing/expired/no TTL)
    my $ok = shm_xx_touch $map, $key;         # reset TTL to default_ttl (LRU promotion still occurs on permanent entries); false if no TTL/LRU
    my $ok = shm_xx_persist $map, $key;       # remove TTL, make key permanent; false on non-TTL maps
    my $ok = shm_xx_set_ttl $map, $key, $sec; # change TTL without changing value (0 = permanent); false on non-TTL maps
    my $n  = shm_xx_flush_expired $map;       # proactively expire all stale entries, returns count
    my ($n, $done) = shm_xx_flush_expired_partial $map, $limit;  # gradual: scan $limit slots

Atomic remove-and-return:

    my $v = shm_xx_take $map, $key;           # remove key and return value (undef if missing)
    my ($k, $v) = shm_xx_pop $map;            # remove+return from LRU tail / scan forward
    my ($k, $v) = shm_xx_shift $map;         # remove+return from LRU head / scan backward
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
    my $ok = shm_xx_reserve $map, $n;          # pre-grow (false if exceeds max)
    my $ev  = shm_xx_stat_evictions $map;     # cumulative LRU eviction count
    my $ex  = shm_xx_stat_expired $map;       # cumulative TTL expiration count
    my $rc  = shm_xx_stat_recoveries $map;   # cumulative stale lock recovery count
    my $p   = $map->path;                     # backing file path (method only)
    my $s   = $map->stats;                   # hashref with all diagnostics in one call
    # stats keys: size, capacity, max_entries, tombstones, mmap_size,
    #   arena_used, arena_cap, evictions, expired, recoveries, max_size, ttl

C<set_multi>, C<stats>, C<path>, and C<unlink> are method-only (no keyword form).

File management:

    $map->unlink;                             # remove backing file (mmap stays valid)
    Data::HashMap::Shared::II->unlink($path); # class method form

=head2 Crash Safety

If a process dies (e.g., SIGKILL, OOM kill) while holding the write lock,
other processes will detect the stale lock within 2 seconds via PID tracking
and automatically recover. The writer's PID is encoded in the rwlock word
itself (single atomic CAS, no crash window), so recovery is reliable even if
the process is killed mid-acquisition. On timeout, waiters check
C<kill($pid, 0)> and CAS-release the lock if the holder is dead.

B<Limitation>: PID-based recovery assumes all processes share the same PID
namespace. Cross-container sharing (different PID namespaces) is not supported.

After recovery from a mid-mutation crash, the map data may be inconsistent.
Calling C<clear> after detecting a stale lock recovery is recommended for
safety-critical applications.

=head1 BENCHMARKS

Throughput versus other shared-memory / on-disk solutions, 25K entries,
single process, Linux x86_64.  Run C<perl -Mblib bench/vs.pl 25000> to reproduce.

    INTEGER KEY -> INTEGER VALUE (Shared::II)
                   Rate BerkeleyDB    LMDB Shared::II
    INSERT       31/s         31      46       184
    LOOKUP       35/s         35      40       383
    INCREMENT    16/s         16      18       165

    STRING KEY -> STRING VALUE, SHORT (inline ≤7B, Shared::SS)
                   Rate FastMmap BerkeleyDB  LMDB SharedMem Shared::SS
    INSERT       11/s       11       26    40       62        130
    LOOKUP       10/s       10       32    34      146        213
    DELETE       14/s       14       18    --       32         68

    STRING KEY -> STRING VALUE, LONG (~50-100B, Shared::SS)
                   Rate BerkeleyDB  LMDB SharedMem Shared::SS
    INSERT       25/s       25      37       61        133
    LOOKUP       30/s       30      33      125        229

    LRU CACHE LOOKUP (25K entries, lock-free clock eviction)
    II plain   350/s    II LRU   373/s  (lock-free, ~6% faster via clock)
    SS plain   159/s    SS LRU   159/s

    CROSS-PROCESS (25K SS entries, 2 processes)
    READS          Shared::SS  3,250,000/s   SharedMem  1,986,000/s   LMDB    728,000/s
    WRITES         Shared::SS  2,801,000/s   SharedMem    826,000/s   LMDB     95,000/s
    MIXED 50/50    Shared::SS  3,691,000/s   SharedMem  1,963,000/s   LMDB    211,000/s

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

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
