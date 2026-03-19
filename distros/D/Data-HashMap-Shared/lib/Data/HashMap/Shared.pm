package Data::HashMap::Shared;
use strict;
use warnings;
our $VERSION = '0.01';

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

=item * Opt-in LRU eviction and per-key TTL (zero cost when disabled)

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

Creates or opens a shared hash map backed by file C<$path>.
C<$max_entries>, C<$max_size>, and C<$ttl> are used only when creating a new
file; when opening an existing one, all parameters are read from the stored
header and the constructor arguments are ignored.
Multiple processes can open the same file simultaneously.
Dies if the file exists but was created by a different variant or is corrupt.

Optional C<$max_size> enables LRU eviction: when the map reaches C<$max_size>
entries, the least-recently-used entry is evicted on insert. Set to 0 (default)
to disable. When LRU is active, C<get> promotes the accessed entry, so reads
take a write lock instead of the lock-free seqlock path.

Optional C<$ttl> sets a default time-to-live in seconds for all entries.
Expired entries are lazily removed on access. Set to 0 (default) to disable.
When TTL is active, C<get> and C<exists> check expiry.

B<Zero-cost when disabled>: with both C<$max_size=0> and C<$ttl=0>, the fast
lock-free read path is used. The only overhead is a branch (predicted away).

=head2 API

Replace C<xx> with variant prefix: C<i16>, C<i32>, C<ii>, C<i16s>,
C<i32s>, C<is>, C<si16>, C<si32>, C<si>, C<ss>.

    my $ok = shm_xx_put $map, $key, $value;   # false if table/arena full
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
    my $n = shm_xx_incr_by $map, $key, $delta;

LRU/TTL operations (require TTL-enabled map for C<put_ttl>):

    my $ok = shm_xx_put_ttl $map, $key, $value, $ttl_sec;  # per-key TTL (0 = permanent); requires TTL-enabled map
    my $ms = shm_xx_max_size $map;            # LRU capacity (0 = disabled)
    my $t  = shm_xx_ttl $map;                 # default TTL in seconds
    my $r  = shm_xx_ttl_remaining $map, $key; # seconds left (0 = permanent, undef if missing/expired/no TTL)
    my $ok = shm_xx_touch $map, $key;         # reset TTL to default_ttl (no-op on permanent entries), promote LRU
    my $n  = shm_xx_flush_expired $map;       # proactively expire all stale entries, returns count
    my ($n, $done) = shm_xx_flush_expired_partial $map, $limit;  # gradual: scan $limit slots

Atomic remove-and-return:

    my $v = shm_xx_take $map, $key;           # remove key and return value (undef if missing)

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
    my $sz  = shm_xx_mmap_size $map;          # backing file size in bytes
    my $ok = shm_xx_reserve $map, $n;          # pre-grow (false if exceeds max)
    my $ev  = shm_xx_stat_evictions $map;     # cumulative LRU eviction count
    my $ex  = shm_xx_stat_expired $map;       # cumulative TTL expiration count
    my $rc  = shm_xx_stat_recoveries $map;   # cumulative stale lock recovery count
    my $p   = $map->path;                     # backing file path (method only)

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
    INSERT       30/s         30      42       172
    LOOKUP       37/s         37      36       372
    INCREMENT    15/s         15      17       164

    STRING KEY -> STRING VALUE (Shared::SS)
                   Rate FastMmap BerkeleyDB  LMDB SharedMem Shared::SS
    INSERT       10/s       10       26    31       46         81
    LOOKUP       10/s       10       33    30      102        151
    DELETE       13/s       13       14    --       27         45

    CROSS-PROCESS (25K SS entries, 2 processes)
    READS          Shared::SS  2,594,000/s   SharedMem  1,547,000/s   LMDB    625,000/s
    WRITES         Shared::SS  2,211,000/s   SharedMem    783,000/s   LMDB    102,000/s
    MIXED 50/50    Shared::SS  3,705,000/s   SharedMem  1,981,000/s   LMDB    226,000/s

LMDB benchmarked with MDB_WRITEMAP|MDB_NOSYNC|MDB_NOMETASYNC|MDB_NORDAHEAD.
BerkeleyDB with DB_PRIVATE|128MB cache.

Key takeaways:

=over

=item * B<10x> faster lookups than LMDB for integer keys (lock-free seqlock path)

=item * B<1.5x> faster than Hash::SharedMem for string lookups

=item * B<4x> faster cross-process reads than LMDB; B<3x> faster writes than SharedMem

=item * Atomic C<incr> is B<10x> faster than get+put on competitors

=back

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
