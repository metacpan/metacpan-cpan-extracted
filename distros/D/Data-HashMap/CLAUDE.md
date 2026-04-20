# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
perl Makefile.PL && make
make test
prove -lv t/01-i32.t           # single test
perl -Mblib bench/all.pl        # benchmarks (all 14 variants vs Perl hash)
perl -Mblib bench/lru.pl        # LRU benchmark vs Tie::Hash::LRU
make clean
```

## Architecture

Data::HashMap is a Perl XS module providing 14 type-specialized hash map variants in C with keyword API via XS::Parse::Keyword.

**Variants:**

| Class | Key | Value | Node Size |
|-------|-----|-------|-----------|
| `Data::HashMap::I16` | int16 | int16 | 4 bytes |
| `Data::HashMap::I16A` | int16 | any SV* | ~24 bytes |
| `Data::HashMap::I16S` | int16 | string | ~24 bytes |
| `Data::HashMap::I32` | int32 | int32 | 8 bytes |
| `Data::HashMap::I32A` | int32 | any SV* | ~24 bytes |
| `Data::HashMap::I32S` | int32 | string | ~24 bytes |
| `Data::HashMap::IA` | int64 | any SV* | ~24 bytes |
| `Data::HashMap::II` | int64 | int64 | 16 bytes |
| `Data::HashMap::IS` | int64 | string | ~24 bytes |
| `Data::HashMap::SA` | string | any SV* | ~32 bytes |
| `Data::HashMap::SI16` | string | int16 | ~24 bytes |
| `Data::HashMap::SI32` | string | int32 | ~24 bytes |
| `Data::HashMap::SI` | string | int64 | ~24 bytes |
| `Data::HashMap::SS` | string | string | ~32 bytes |

**Layer structure:**
- `lib/Data/HashMap.pm` — Main module, loads XS via XSLoader, POD documentation
- `lib/Data/HashMap/{I16,I16A,I16S,I32,I32A,I32S,IA,II,IS,SA,SI16,SI32,SI,SS}.pm` — Variant modules, enable keywords via `$^H` hints
- `HashMap.xs` — XS bindings + XS::Parse::Keyword integration for all 14 variants
- `hashmap_generic.h` — Macro-template C implementation (included 14 times with different defines)
- `hashmap_{i16,i16a,i16s,i32,i32a,i32s,ia,ii,is,sa,si16,si32,si,ss}.h` — Variant instantiation headers
- `typemap` — XS type mappings

**Key implementation details:**
- Open addressing with linear probing, xxHash-based hash functions
- Automatic resize at 75% load factor, initial capacity 16
- Tombstone deletion with automatic compaction (>25% tombstones or tombstones > live)
- Sentinel values for integer keys (INT_MIN, INT_MIN+1 are reserved)
- UTF-8 flag packed into high bit of uint32_t length fields
- OOM-safe put: all memory pre-allocated before modifying map state
- Keywords bypass Perl method dispatch for maximum performance

## API

```perl
use Data::HashMap::II;
my $map = Data::HashMap::II->new();
hm_ii_put $map, 42, 100;
my $val = hm_ii_get $map, 42;      # 100
hm_ii_remove $map, 42;
my $old = hm_ii_take $map, 42;     # remove + return value
my @kv = hm_ii_drain $map, 10;    # remove up to 10 entries as (k1,v1,...)
my ($k,$v) = hm_ii_pop $map;      # remove+return from LRU tail (or iter forward)
my ($k,$v) = hm_ii_shift $map;    # remove+return from LRU head (or iter backward)
hm_ii_reserve $map, 100000;       # pre-allocate capacity
hm_ii_purge $map;                  # force-expire all TTL entries
my $copy = $map->clone;            # deep copy
$map->from_hash(\%h);              # bulk-insert from hashref
$map->merge($other_map);           # merge another map into this one
my $old = $map->swap(42, 99);      # replace value, return old
my $ok = $map->cas(42, 99, 100);   # compare-and-swap (int-value only)
hm_ii_capacity $map;               # internal table capacity
hm_ii_persist $map, 42;            # remove TTL from key
my $bin = $map->freeze;            # binary serialize (non-SV*)
my $map2 = Data::HashMap::II->thaw($bin);  # deserialize
my $count = hm_ii_incr $map, 1;    # 1
my @keys = hm_ii_keys $map;
hm_ii_clear $map;                   # remove all entries
my $h = hm_ii_to_hash $map;         # Perl hashref snapshot
hm_ii_put_ttl $map, 1, 10, 30;      # insert with 30s per-key TTL
my $v = hm_ii_get_or_set $map, 1, 0; # get or insert default
my $d = hm_is_get_direct $map, 1;    # zero-copy get (read-only, no SV alloc)
```

Replace `ii` with variant prefix: `i16`, `i16a`, `i16s`, `i32`, `i32a`, `i32s`, `ia`, `ii`, `is`, `sa`, `si16`, `si32`, `si`, `ss`.
Integer-value variants (I16, I32, II, SI16, SI32, SI) also have: `incr`, `decr`, `incr_by`.
SV* variants (I16A, I32A, IA, SA) store arbitrary Perl values (refs, objects, coderefs) with proper refcounting.
String-value variants (IS, SS, I32S, I16S) also have: `get_direct` (zero-copy get, returns read-only SV with no buffer allocation — unsafe if map mutates).

Constructor: `->new()` plain, `->new($max_size)` LRU, `->new(0, $ttl)` TTL, `->new($max_size, $ttl)` both, `->new($max_size, 0, $lru_skip)` LRU with skip.
Accessors: `hm_xx_max_size $map`, `hm_xx_ttl $map`, `hm_xx_lru_skip $map`.
`lru_skip` (0-99): approximate LRU — skips promotion on most reads. Recommended: 90 for caching workloads.

**Keyword syntax constraints:**
- Do NOT use parenthesized calls: `keyword $a, $b` not `keyword($a, $b)`
- For sort without a block: `sort (hm_xx_keys $map)` not `sort hm_xx_keys $map` (a block disambiguates: `sort { $a cmp $b } hm_xx_keys $map` is fine)

## Dependencies

- `XS::Parse::Keyword` (>= 0.40) — For custom keyword syntax
- `Devel::PPPort` — Perl version compatibility
