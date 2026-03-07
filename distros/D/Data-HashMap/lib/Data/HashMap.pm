package Data::HashMap;

use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Data::HashMap', $VERSION);

1;

__END__

=head1 NAME

Data::HashMap - Fast type-specialized hash maps implemented in C

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
    my $val = $map->get(42);         # 100
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
    while (my ($k, $v) = hm_ii_each $map) { ... }

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

Data::HashMap provides fourteen type-specialized hash map implementations
in C, each optimized for its specific key/value type combination.
All data access uses keyword syntax, which bypasses Perl's method
dispatch for maximum performance. A method-call API
(C<< $map->get($key) >>) is also available for convenience.

Keywords are automatically enabled when you C<use> a variant module.

=head1 VARIANTS

=over

=item L<Data::HashMap::I16> - int16 keys, int16 values (4 bytes/entry)

=item L<Data::HashMap::I16A> - int16 keys, any Perl SV* values (refs, objects, etc.)

=item L<Data::HashMap::I16S> - int16 keys, string values

=item L<Data::HashMap::I32> - int32 keys, int32 values (8 bytes/entry)

=item L<Data::HashMap::I32A> - int32 keys, any Perl SV* values (refs, objects, etc.)

=item L<Data::HashMap::I32S> - int32 keys, string values

=item L<Data::HashMap::II> - int64 keys, int64 values (16 bytes/entry)

=item L<Data::HashMap::IA> - int64 keys, any Perl SV* values (refs, objects, etc.)

=item L<Data::HashMap::IS> - int64 keys, string values

=item L<Data::HashMap::SA> - string keys, any Perl SV* values (refs, objects, etc.)

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
    hm_xx_size $map                 # returns entry count

    # List-returning:
    hm_xx_keys $map                 # returns list of keys
    hm_xx_values $map               # returns list of values
    hm_xx_items $map                # returns (k1,v1, k2,v2, ...)

Integer-value variants (I16, I32, II, SI16, SI32, SI) also provide:

    hm_xx_incr $map, $key           # +1, returns new value (new keys init to 0)
    hm_xx_decr $map, $key           # -1, returns new value (new keys init to 0)
    hm_xx_incr_by $map, $key, $n    # +N, returns new value (new keys init to 0)

All variants also provide:

    hm_xx_max_size $map             # returns max_size (0 = no LRU)
    hm_xx_ttl $map                  # returns default TTL in seconds (0 = no TTL)
    hm_xx_clear $map                # remove all entries
    hm_xx_to_hash $map              # returns a Perl hashref snapshot
    hm_xx_each $map                            # returns (key, value) or empty list
    hm_xx_iter_reset $map                      # reset each() iterator to start
    hm_xx_put_ttl $map, $key, $val, $seconds   # insert with per-key TTL
    hm_xx_get_or_set $map, $key, $default      # get existing or insert default

=head1 CONSTRUCTOR

    my $map  = Data::HashMap::II->new();           # plain (no LRU, no TTL)
    my $lru  = Data::HashMap::II->new(1000);       # LRU: max 1000 entries
    my $ttl  = Data::HashMap::II->new(0, 60);      # TTL: 60-second expiry
    my $both = Data::HashMap::II->new(1000, 60);   # LRU + TTL

=head2 LRU eviction

When C<max_size> is set, the map acts as an LRU cache. Inserting beyond
capacity evicts the least-recently-used entry. C<get>, C<put> (update),
and counter operations promote the accessed entry to most-recently-used.

=head2 TTL expiry

When C<default_ttl> is set (in seconds), entries expire lazily: expired
entries are removed on access (C<get>, C<exists>, counter ops) and
skipped during iteration (C<keys>, C<values>, C<items>, C<each>, C<to_hash>). Note that
C<hm_xx_size> returns the count of all inserted entries including those
past their TTL that have not yet been lazily removed. C<exists> does not
promote entries in LRU mode (read-only check).

Individual entries can also be given a per-key TTL via C<hm_xx_put_ttl>
or C<< $map->put_ttl($key, $value, $seconds) >>, even on maps created
without a default TTL. The expires array is lazily allocated on first use.

Both features use parallel arrays indexed by slot, keeping the core
node struct unchanged. Maps created without LRU/TTL have zero overhead
beyond a never-taken branch.

=head1 PERFORMANCE

Benchmarks with 100k entries on Linux x86_64 (higher is better):

    INSERT (iterations/sec):
              Rate perl_ss perl_ii    SA    SS  SI32    SI  I32S    IS   II  I32  I16
    perl_ss 18.0/s      --     -0%  -10%  -24%  -49%  -50%  -50%  -51% -80% -80% -95%
    perl_ii 18.1/s      0%      --  -10%  -23%  -49%  -50%  -50%  -50% -80% -80% -94%
    SA      20.1/s     11%     11%    --  -15%  -43%  -44%  -44%  -45% -77% -77% -94%
    SS      23.6/s     31%     30%   17%    --  -33%  -34%  -34%  -35% -73% -73% -93%
    SI32    35.4/s     96%     96%   76%   50%    --   -1%   -1%   -3% -59% -60% -89%
    SI      35.8/s     99%     98%   79%   52%    1%    --   -0%   -2% -59% -59% -89%
    I32S    35.9/s     99%     99%   79%   52%    2%    0%    --   -1% -59% -59% -89%
    IS      36.5/s    102%    102%   82%   55%    3%    2%    1%    -- -58% -59% -89%
    II      88.2/s    390%    388%  340%  274%  149%  146%  146%  142%   --  -1% -73%
    I32     87.1/s    383%    382%  334%  269%  146%  143%  142%  139%  -1%   -- -73%
    I16      328/s   1722%   1717% 1536% 1293%  828%  817%  814%  801% 272% 277%   --

    LOOKUP (iterations/sec):
              Rate    SS  SI32    SI perl_ii perl_ss  I32S    IS    II   I32   I16
    SS      27.1/s    --   -6%   -6%    -25%    -29%  -42%  -47%  -69%  -71%  -93%
    SI32    28.9/s    7%    --   -0%    -20%    -25%  -38%  -43%  -66%  -69%  -92%
    SI      28.9/s    7%    0%    --    -20%    -25%  -38%  -43%  -66%  -69%  -92%
    perl_ii 36.0/s   33%   25%   25%      --     -6%  -23%  -29%  -58%  -62%  -90%
    perl_ss 38.3/s   42%   32%   33%      6%      --  -18%  -25%  -55%  -60%  -89%
    I32S    47.0/s   74%   63%   63%     31%     23%    --   -8%  -45%  -50%  -87%
    IS      51.1/s   89%   77%   77%     42%     33%    9%    --  -41%  -46%  -86%
    II      86.0/s  218%  197%  198%    139%    124%   83%   68%    --   -9%  -76%
    I32     94.7/s  250%  227%  228%    163%    147%  101%   85%   10%    --  -74%
    I16      365/s 1249% 1162% 1165%    913%    852%  676%  614%  325%  285%    --

    ITERATE with each() (iterations/sec):
              Rate perl_ii perl_ss    SS    IS    SI    II   I32   I16
    perl_ii 34.6/s      --     -6%  -16%  -30%  -37%  -52%  -53%  -87%
    perl_ss 36.8/s      6%      --  -11%  -26%  -33%  -48%  -50%  -86%
    SS      41.4/s     20%     13%    --  -17%  -24%  -42%  -43%  -84%
    IS      49.7/s     44%     35%   20%    --   -9%  -30%  -32%  -81%
    SI      54.7/s     58%     48%   32%   10%    --  -24%  -25%  -79%
    II      71.5/s    106%     94%   72%   44%   31%    --   -2%  -72%
    I32     73.1/s    111%     98%   76%   47%   34%    2%    --  -72%
    I16      257/s    643%    598%  520%  417%  370%  260%  252%    --

    ITERATE with keys() (iterations/sec):
              Rate perl_ii perl_ss    SS    SI    II   I32
    perl_ii 89.0/s      --     -3%  -34%  -41%  -76%  -77%
    perl_ss 92.1/s      3%      --  -32%  -39%  -75%  -77%
    SS       135/s     52%     47%    --  -11%  -63%  -66%
    SI       151/s     70%     64%   12%    --  -59%  -62%
    II       367/s    313%    299%  172%  143%    --   -7%
    I32      395/s    343%    328%  192%  161%    7%    --

    ITERATE with items() vs each-in-loop (iterations/sec):
                Rate perl_each   perl_kv   SS_each   II_each  SS_items  II_items
    perl_each 35.3/s        --      -13%      -16%      -52%      -53%      -83%
    perl_kv   40.4/s       14%        --       -4%      -45%      -47%      -81%
    SS_each   42.2/s       20%        5%        --      -42%      -44%      -80%
    II_each   73.0/s      107%       81%       73%        --       -3%      -66%
    SS_items  75.5/s      114%       87%       79%        3%        --      -65%
    II_items   214/s      505%      429%      406%      192%      183%        --

=head2 LRU / TTL overhead

LRU and TTL add parallel arrays for linked-list pointers and expiry timestamps.
Maps created without these features have zero overhead beyond a never-taken branch.

    INSERT, II variant (iterations/sec):
                 Rate II_lru_ttl     II_lru         II
    II_lru_ttl 65.9/s         --        -3%       -26%
    II_lru     68.1/s         3%         --       -24%
    II         89.6/s        36%        32%         --

    LOOKUP, II variant (iterations/sec):
                 Rate II_lru_ttl     II_lru         II
    II_lru_ttl 69.5/s         --        -8%       -22%
    II_lru     75.7/s         9%         --       -15%
    II         89.3/s        29%        18%         --

    LRU EVICTION CHURN: insert 100k into capacity 50k (iterations/sec):
                 Rate II_lru_ttl     II_lru
    II_lru_ttl 75.8/s         --        -5%
    II_lru     79.4/s         5%         --

=head2 Method vs keyword overhead

Keywords bypass Perl's method dispatch for maximum performance. Method calls
(C<< $map->get($key) >>) are convenient but slower:

    II variant, 100k operations (iterations/sec):
                    keyword    method    overhead
    LOOKUP           87.4/s    75.5/s       -14%
    INSERT           85.2/s    76.0/s       -11%

=head1 MEMORY

Memory usage with 1M entries (fork-isolated measurements):

    Variant       Memory       Bytes/entry   vs Perl hash
    -------       ------       -----------   ------------
    I16*           0.5 MB        19            9x less
    I32            28 MB         30            5.5x less
    II             44 MB         46            3.5x less
    I32S           72 MB         75            2.3x less
    IS             72 MB         75            2.3x less
    SI16           72 MB         75            2.3x less
    SI32           72 MB         75            2.3x less
    SI             72 MB         75            2.3x less
    SS            118 MB        124            1.4x less
    SA            137 MB        144            1.2x less
    IA             90 MB         95            1.8x less
    perl %h (int) 155 MB        163            (baseline)
    perl %h (str) 162 MB        170            (baseline)

    * I16 measured at 30k entries (int16 key range limits max unique keys to ~65k)

=head2 LRU / TTL memory overhead

Overhead per entry for LRU (prev/next pointers) and TTL (expiry timestamp),
measured with 1M entries in fork-isolated processes.

    II variant (int64/int64):
    Variant        Bytes/entry   LRU overhead   +TTL overhead
    -------        -----------   ------------   -------------
    II                    46.5       -              -
    II_lru                67.4     +20.9 B          -
    II_lru_ttl            80.0       -            +12.6 B

    SS variant (string/string, various key+value sizes):
    Variant        Bytes/entry   LRU overhead   +TTL overhead
    -------        -----------   ------------   -------------
    SS  8B keys          124.0       -              -
    SS  8B lru           140.8     +16.8 B          -
    SS  8B lru+ttl       152.3       -            +11.5 B
    SS 16B keys          124.0       -              -
    SS 16B lru           140.8     +16.8 B          -
    SS 16B lru+ttl       152.3       -            +11.5 B
    SS 32B keys          156.0       -              -
    SS 32B lru           172.8     +16.8 B          -
    SS 32B lru+ttl       181.2       -             +8.4 B
    SS 64B keys          220.0       -              -
    SS 64B lru           236.8     +16.8 B          -
    SS 64B lru+ttl       245.2       -             +8.4 B

=head1 IMPLEMENTATION

=over

=item * Open addressing with linear probing

=item * xxHash-inspired hash functions (64-bit mix for integers, 32-bit mix for strings)

=item * Automatic resize at 75% load factor

=item * Tombstone deletion with automatic compaction

=item * Raw C strings (no Perl SV overhead) for string storage

=item * UTF-8 flag packed into high bit of length fields

=item * Sentinel values for integer keys (INT_MIN, INT_MIN+1 are reserved)

=back

=head1 DEPENDENCIES

L<XS::Parse::Keyword> (>= 0.40)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
