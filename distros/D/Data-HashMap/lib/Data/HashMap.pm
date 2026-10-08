package Data::HashMap;

use strict;
use warnings;

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Data::HashMap', $VERSION);

sub CLONE_SKIP { 1 }

sub STORABLE_freeze { $_[0]->freeze }

sub STORABLE_thaw {
    my ($self, undef, $blob) = @_;
    my $tmp = ref($self)->thaw($blob);
    $$self = $$tmp;
    $$tmp  = 0;
    return;
}

for my $v (qw(I16 I16A I16S I32 I32A I32S IA II IS SA SI16 SI32 SI SS)) {
    no strict 'refs';
    @{"Data::HashMap::${v}::ISA"} = (__PACKAGE__);
}

1;

__END__

=head1 NAME

Data::HashMap - Fast type-specialized hash maps with TTL and LRU, in C

=head1 SYNOPSIS

    use Data::HashMap::II;

    # Keyword API (fastest - bypasses method dispatch)
    my $map = Data::HashMap::II->new();
    hm_ii_put $map, 42, 100;
    my $val = hm_ii_get $map, 42;    # 100
    hm_ii_exists $map, 42;           # true
    hm_ii_remove $map, 42;

    # Method API (convenient - same operations)
    $map->put(42, 100);
    $val = $map->get(42);            # 100
    $map->exists(42);                # true
    $map->remove(42);

    # Counter operations (integer-value variants only)
    my $count = hm_ii_incr $map, 1;  # 1
    $count = hm_ii_incr $map, 1;     # 2
    $count = hm_ii_decr $map, 1;     # 1

    # Iteration
    my @keys   = hm_ii_keys $map;
    my @values = hm_ii_values $map;
    my @pairs  = hm_ii_items $map;   # (k1, v1, k2, v2, ...)
    while (my ($k, $v) = hm_ii_each $map) { print "$k=$v\n" }

    # Bulk operations
    my $href = hm_ii_to_hash $map;   # Perl hashref snapshot
    hm_ii_clear $map;                # remove all entries

    # LRU cache (max 1000 entries, evicts least-recently-used)
    my $lru = Data::HashMap::II->new(1000);

    # TTL cache (entries expire after 60 seconds)
    my $ttl = Data::HashMap::II->new(0, 60);

    # LRU + TTL combined
    my $both = Data::HashMap::II->new(1000, 60);

    # Per-key TTL
    hm_ii_put_ttl $map, 42, 100, 30;   # expires in 30 seconds

    # Get or set default
    my $v = hm_ii_get_or_set $map, 99, 0;  # insert 0 if key 99 absent

=head1 DESCRIPTION

Fourteen hash maps implemented in C, each specialised for one combination of
key and value type. Most operations are available both as a keyword, which
bypasses method dispatch, and as a method (C<< $map->get($key) >>); a few are
methods only.

Keywords are enabled by C<use Data::HashMap::XX> for the rest of the enclosing
lexical scope, normally the file. Each file that calls them needs its own
C<use> line; C<use Data::HashMap::XX ()> does not enable them. Without it a call
still compiles, as a method call, and fails when it runs with
C<Can't locate object method "hm_xx_get" via package "Data::HashMap::XX">.

=head1 VARIANTS

=over

=item L<Data::HashMap::I16> - int16 keys, int16 values (4-byte node)

=item L<Data::HashMap::I16A> - int16 keys, any Perl value

=item L<Data::HashMap::I16S> - int16 keys, string values

=item L<Data::HashMap::I32> - int32 keys, int32 values (8-byte node)

=item L<Data::HashMap::I32A> - int32 keys, any Perl value

=item L<Data::HashMap::I32S> - int32 keys, string values

=item L<Data::HashMap::II> - int64 keys, int64 values (16-byte node)

=item L<Data::HashMap::IA> - int64 keys, any Perl value

=item L<Data::HashMap::IS> - int64 keys, string values

=item L<Data::HashMap::SA> - string keys, any Perl value

=item L<Data::HashMap::SI16> - string keys, int16 values

=item L<Data::HashMap::SI32> - string keys, int32 values

=item L<Data::HashMap::SI> - string keys, int64 values

=item L<Data::HashMap::SS> - string keys, string values

=back

=head1 KEYWORDS

Each variant provides the following keywords (replace C<xx> with the
variant prefix: C<i16>, C<i16a>, C<i16s>, C<i32>, C<i32a>, C<i32s>, C<ia>, C<ii>, C<is>, C<sa>, C<si16>, C<si32>, C<si>, C<ss>):

    hm_xx_put $map, $key, $value    # insert/update, returns bool
    hm_xx_get $map, $key            # lookup, returns value or undef
    hm_xx_exists $map, $key         # returns bool
    hm_xx_remove $map, $key         # returns bool
    hm_xx_take $map, $key           # remove and return value, or undef
    hm_xx_drain $map, $n            # remove up to N entries, returns (k1,v1,...)
    hm_xx_pop $map                  # remove+return (key,val): LRU tail or next entry
    hm_xx_shift $map                # remove+return (key,val): LRU head or prev entry
    hm_xx_reserve $map, $n          # pre-allocate capacity for N entries
    hm_xx_purge $map                # reap already-expired TTL entries
    hm_xx_capacity $map             # current internal table capacity
    hm_xx_persist $map, $key        # remove TTL from key (make permanent)
    hm_xx_swap $map, $key, $new     # replace value, return old (undef if missing)

Integer-value variants (I16, I32, II, SI16, SI32, SI) also provide:

    hm_xx_incr $map, $key           # +1, returns new value (new keys init to 0)
    hm_xx_decr $map, $key           # -1, returns new value (new keys init to 0)
    hm_xx_incr_by $map, $key, $n    # +N, returns new value (new keys init to 0)
    hm_xx_cas $map, $key, $expected, $new  # compare-and-swap, returns bool

All variants also provide:

    hm_xx_size $map                 # entry count, including expired entries not yet reaped
    hm_xx_keys $map                 # returns list of keys
    hm_xx_values $map               # returns list of values
    hm_xx_items $map                # returns (k1,v1, k2,v2, ...)

    hm_xx_max_size $map             # returns max_size (0 = no LRU)
    hm_xx_ttl $map                  # returns default TTL in seconds (0 = no TTL)
    hm_xx_lru_skip $map             # returns lru_skip percentage (0 = strict LRU)
    hm_xx_clear $map                # remove all entries
    hm_xx_to_hash $map              # returns a Perl hashref snapshot
    hm_xx_each $map                            # returns (key, value) or empty list
    hm_xx_iter_reset $map                      # reset each() iterator to start
    hm_xx_put_ttl $map, $key, $val, $seconds   # insert with per-key TTL ($seconds=0 uses map default)
    hm_xx_get_or_set $map, $key, $default      # get existing or insert default

String-value variants (SS, IS, I32S, I16S) also provide:

    hm_xx_get_direct $map, $key   # zero-copy get (read-only, see CAVEATS)

Method-only operations (no keyword form):

    $map->clone                     # copy the map (SV* values per its copy mode)
    $map->from_hash(\%h)            # bulk-insert from a Perl hashref
    $map->merge($other_map)         # copy in another same-variant map's entries
    $map->freeze                    # serialize to binary string (non-SV* variants)
    MyVariant->thaw($data)          # rebuild a frozen map (non-SV* variants)

=head1 CONSTRUCTOR

    my $map  = Data::HashMap::II->new();              # plain (no LRU, no TTL)
    my $lru  = Data::HashMap::II->new(1000);          # LRU: max 1000 entries
    my $ttl  = Data::HashMap::II->new(0, 60);         # TTL: 60-second expiry
    my $both = Data::HashMap::II->new(1000, 60);      # LRU + TTL
    my $fast = Data::HashMap::II->new(1000, 0, 90);   # LRU + 90% skip
    my $safe = Data::HashMap::SA->new(0, 0, 0, 1);    # SV* variants: copy values

The arguments are C<max_size>, C<ttl> in seconds, and C<lru_skip>, each a
non-negative number; the SV* variants take a fourth, C<copy> (see
L</CAVEATS>). A reference, a non-numeric string or an extra argument croaks; a C<ttl> below one second rounds up to one, and one beyond 2**32
seconds saturates.

=head2 LRU eviction

With C<max_size> set, inserting a new key into a full map evicts the least
recently used entry. Reading or writing an existing key promotes it: C<get>,
C<get_direct>, C<put>, C<put_ttl>, C<swap>, a successful C<cas>,
C<get_or_set> and the counters do; C<exists>, C<persist> and a failed C<cas>
do not.

C<lru_skip> (0-99, larger values clamp to 99) skips promotion on exactly that
percentage of the accesses that would promote: 90 promotes one in ten. The
least recently used entry is always promoted when touched, so it cannot be
starved, and touching the most recently used one never counts. This trades
eviction precision for speed on read-heavy workloads with hot keys; 90 suits
most caches.

=head2 TTL expiry

With a default C<ttl>, or a per-key one from C<put_ttl> (which also works on a
map without a default), entries expire lazily, with one-second resolution: an
entry with a TTL of I<n> seconds is readable for between I<n> and I<n>+1
seconds. Iteration (C<keys>, C<values>, C<items>, C<each>, C<to_hash>) skips
expired entries, and C<get>, C<exists> and the counters remove one they touch;
C<size> counts expired entries until they are removed.

Entries nobody touches again are reaped when the table would otherwise grow, so
a map fed never-repeating keys stays bounded, at a few times its live set.
C<purge> reaps every expired entry on demand and never removes a live one.

On a map with a default TTL, C<put> and the counters renew an existing entry's
lifetime to that default -- even one given its own TTL by C<put_ttl> or made
permanent by C<persist> -- so a counter that keeps being hit never expires.
C<swap>, C<cas>, C<get_or_set> on an existing key, and reads leave the expiry
alone. On a map without a default the counters leave it alone too, while C<put>
clears any C<put_ttl> deadline. C<get_or_set> inserts with the default TTL; use
C<put_ttl> for a per-key one.

On a map with both C<max_size> and a TTL, eviction takes the least recently
used entry whether or not it has expired, and an expired entry keeps its slot
and its value until it is reaped: call C<purge> periodically so that expired
entries, not live ones, make room.

Expiry is measured against the wall clock (C<time>), so stepping the system
clock moves every deadline with it; a clock set backward keeps entries alive
longer.

=head1 CAVEATS

=over

=item Keyword syntax

A keyword taking two or more arguments takes a plain comma list with no
parentheses: C<hm_ii_get $m, $k>. C<hm_ii_get($m, $k)> fails to compile with
"Expected ','", and C<< => >> is not a separator; one-argument keywords such as
C<hm_xx_size($m)> do accept parentheses. A keyword parses like a list operator,
so everything after the last comma is the last argument:
C<< hm_xx_get $m, $k // $default >> looks up C<< $k // $default >>.
Parenthesise the call when an operator follows it:
C<< (hm_xx_get $m, $k) // $default >>, C<< (hm_sa_get $m, $id)->{field} >>.
C<hm_xx_keys>, C<hm_xx_values> and C<hm_xx_items> return the entry count in
scalar context, which on a TTL map includes expired entries the list form
skips. C<no Data::HashMap::XX> does not remove the keywords.

=item Integers

Keys and values are checked against the variant's range on every call,
C<from_hash> included, and croak outside it rather than wrap. NaN croaks
wherever a number is expected. INT_MIN and INT_MIN+1 are reserved as keys:
C<put>, C<put_ttl>, C<get_or_set> and lookups ignore them, as do C<swap> and
C<cas> (returning undef and false), while C<incr>, C<decr> and C<incr_by>
croak. An undef key or value coerces as in Perl, to C<""> or 0, usually with
a warning; SV* variants store an undef value as-is. The counters croak rather
than overflow, leaving the value unchanged: C<incr> with C<increment failed>,
C<decr> with C<decrement failed> and C<incr_by> with C<incr_by failed>. The
I16 and I32 croaks name the full type range, reserved values included. A
64-bit perl (C<use64bitint>) is required.

=item String keys

Identity is the key's bytes. A UTF-8-flagged key whose characters fit in one
byte is downgraded first, so C<"caf\xe9"> and its upgraded form are one key, as
in a hash. A key that needs UTF-8 is returned with the flag of its most recent
C<put>, and collides with its own encoded octets: C<"\x{263a}"> and
C<"\xe2\x98\xba"> are one key here and two in a hash, so copying a hash that
holds both into a map keeps only one.

=item Perl values

By default the SV* variants (I16A, I32A, IA, SA) store the SV you pass, not a
copy, as 0.08 did. That is the fastest option, but the stored value stays tied
to the caller's variable: storing C<$_> in a C<while (E<lt>$fhE<gt>)> loop
leaves every entry holding the loop's final C<undef>; a C<substr> result, C<$1>
or a C<foreach> variable changes after it is stored; C<from_hash>, C<clone>,
C<merge> and C<to_hash> share SVs with their source; and a stored literal is
read-only. Store a copy (C<"$_">), or pass a true fourth argument, C<copy>, to
C<new>: the map then copies each value it stores, as a hash does, at the cost
of one SV copy per put. In either mode C<get>, C<values>, C<items> and C<each>
return the map's own SV, as C<values %h> does, and referents are shared.

=item Iteration and order

Key order is unspecified and differs between processes, as with Perl's own
hashes; sort if you need a stable one. C<each> restarts after C<clear>, and
whenever another write resizes or compacts the table (C<swap>, C<cas> and
C<persist> only do so by reaping an expired entry), so do not write to the
map during C<each>; reads are safe. In scalar context it returns the key, so
a C<while> loop over it must guard with C<defined> -- C<while (defined(my $k =
hm_xx_each $map))> -- or it stops early on a false key such as C<0> or C<"">.
C<pop>, C<shift> and C<drain> keep their own cursor, so they do not move an
C<each> in progress unless they compact the table. On an LRU map C<pop> and
C<shift> take the least and most recently used entry; C<drain> always goes in
table order. In scalar context the three return the last value removed.
C<pop> and C<shift> skip expired entries; on an LRU map they also reap them,
and on a plain map C<size> keeps counting them until a lookup reaps them.

=item get_direct

Returns a read-only SV that borrows the map's buffer instead of copying it, for
immediate use such as comparing or printing. It is valid until that entry is
next changed, removed, reaped or evicted, so on a TTL or LRU map treat it as
valid only until the next call on the map. Arguments are evaluated before a
call: C<< f($m->get_direct($k), $m->remove($k)) >> hands C<f> freed memory.
C<< my $d = $m->get_direct($k) >> copies, so C<$d> is safe to keep.

=item freeze and thaw

The format is native-endian and not portable across byte orders. Output is not
byte-stable -- table order drifts across rehashes and, with the per-process hash
seed, between runs -- so do not use a frozen blob as a digest or cache key;
C<thaw> round-trips the data regardless. Each entry's remaining lifetime is
stored, and C<thaw> starts that countdown afresh, so time spent frozen does not
count. A C<thaw>ed LRU map has lost its recency order. A map whose
C<max_size> exceeds 4294967295 cannot be frozen: the format stores it in 32
bits, so C<freeze> croaks. All of this applies to L<Storable> too.

=item from_hash and merge

C<from_hash> croaks on a key or value the matching C<put> would reject, leaving
the entries inserted so far in place, skips reserved keys silently, and reads
tied hashes. C<merge> copies another map's entries in, the other map winning a
conflict; they take this map's TTL rules, not the other map's, so merging into
a map without a TTL makes them permanent. Already-expired entries are skipped.

=item Capacity

A table never shrinks: C<remove> and C<clear> keep its capacity for reuse;
build a new map to release the memory. The table is the next power of two at or
above 4/3 of the entries it holds, so a full LRU map's table is between about
1.34 and 4 times C<max_size>: smaller while filling, larger after a C<reserve>.

=item Taint

The string-value variants (I16S, I32S, IS, SS) keep values in plain C buffers,
so a tainted string comes back untainted. Under C<-T> do not round-trip
untrusted data through them into a sensitive operation; the SV* variants
preserve taint. Keys are never tainted, as with Perl's hashes.

=back

=head1 STORABLE

L<Storable>'s C<freeze>, C<thaw> and C<dclone> work on the ten variants with a
native C<freeze>, through that format, and produce a separate map. The four SV*
variants croak with C<freeze not supported for SV* variants; use to_hash +
Storable>. L<Clone> and other deep copiers that duplicate a blessed scalar
without a hook are not supported: the copy would share the C table and free it
twice.

=head1 THREADS

Maps are not shared between ithreads. Every variant inherits C<CLONE_SKIP> from
C<Data::HashMap>, so a child thread keeps the reference but it points at an
unblessed C<undef>, and C<DESTROY> never runs on it there; without that, both
interpreters would free the same C table. Test with
C<Scalar::Util::blessed($map)>. A thread that needs a map should build its own,
or receive the contents as a plain hash via C<to_hash>.

=head1 PERFORMANCE

Measure on your own machine with C<perl -Mblib bench/all.pl>; speed varies with
hardware, Perl build and table size, so treat only the shape as portable.

Inserts into an integer-key map beat a Perl hash at every size -- roughly 2x at
a thousand entries, widening to several times at 100k; string-key maps are
faster too, by a smaller margin. Lookups trade places with size: on a small
map a Perl hash is quicker, and the C map pulls ahead as the table fills, so
the win is largest on big, long-lived maps. Within one key width the variants
run at about the same speed -- the narrower integer types buy memory and range
checks, not throughput. A keyword call is a little cheaper than the method
form.

=head1 MEMORY

Bytes per entry at 1M entries, fork-isolated (16-bit rows at 30k, where int16
caps unique keys near 65k; each row exceeds its node size because the table is
a power of two above 4/3 of the entries):

    Variant       Bytes/entry   vs Perl hash
    I16/I16A/I16S          21      8x less
    I32                    30    5.5x less
    II                     46    3.5x less
    I32S/IS/SI/SI16/SI32   75    2.2x less
    I32A/IA                95    1.7x less
    SS                    124    1.3x less
    SA                    144    1.1x less
    perl %h (int/str)  163/170   baseline

LRU adds about 17-21 bytes per entry (two slot indices) and a TTL about 8-13
more (an expiry timestamp); each array is allocated only when its feature is
used.

=head1 IMPLEMENTATION

=over

=item * Open addressing with linear probing; tombstone deletion with automatic compaction

=item * xxHash v0.8.3 (C<XXH3_64bits_withSecret>) for integer and string keys, keyed by a secret derived at load time from Perl's hash seed for DoS resistance

=item * Resize at 75% load; initial capacity 16

=item * LRU and TTL state in parallel arrays indexed by slot, allocated only when used, so a map without them pays one never-taken branch

=item * Strings stored as raw C buffers, with the UTF-8 flag in the high bit of the length

=back

=head1 DEPENDENCIES

L<XS::Parse::Keyword> (>= 0.40)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
