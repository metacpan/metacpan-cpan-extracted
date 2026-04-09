package Data::HashMap;

use strict;
use warnings;

our $VERSION = '0.07';

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
    hm_xx_take $map, $key           # remove and return value, or undef
    hm_xx_drain $map, $n            # remove up to N entries, returns (k1,v1,...)
    hm_xx_pop $map                  # remove+return (key,val): LRU tail or next entry
    hm_xx_shift $map                # remove+return (key,val): LRU head or prev entry
    hm_xx_reserve $map, $n          # pre-allocate capacity for N entries
    hm_xx_purge $map                # force-expire all TTL'd entries
    hm_xx_capacity $map             # current internal table capacity
    hm_xx_persist $map, $key        # remove TTL from key (make permanent)
    hm_xx_swap $map, $key, $new     # replace value, return old (undef if missing)

Integer-value variants (I16, I32, II, SI16, SI32, SI) also provide:

    hm_xx_incr $map, $key           # +1, returns new value (new keys init to 0)
    hm_xx_decr $map, $key           # -1, returns new value (new keys init to 0)
    hm_xx_incr_by $map, $key, $n    # +N, returns new value (new keys init to 0)
    hm_xx_cas $map, $key, $expected, $new  # compare-and-swap, returns bool

All variants also provide:

    hm_xx_size $map                 # returns entry count (includes TTL-expired not yet reaped)
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

    $map->clone                     # deep copy the map
    $map->from_hash(\%h)            # bulk-insert from a Perl hashref
    $map->merge($other_map)         # merge entries from another map of same type
    $map->freeze                    # serialize to binary string (non-SV* variants)
    MyVariant->thaw($data)          # reconstruct map from freeze data

=head1 CONSTRUCTOR

    my $map  = Data::HashMap::II->new();              # plain (no LRU, no TTL)
    my $lru  = Data::HashMap::II->new(1000);          # LRU: max 1000 entries
    my $ttl  = Data::HashMap::II->new(0, 60);         # TTL: 60-second expiry
    my $both = Data::HashMap::II->new(1000, 60);      # LRU + TTL
    my $fast = Data::HashMap::II->new(1000, 0, 90);   # LRU + 90% skip

=head2 LRU eviction

When C<max_size> is set, the map acts as an LRU cache. Inserting beyond
capacity evicts the least-recently-used entry. C<get>, C<put> (update),
and counter operations promote the accessed entry to most-recently-used.

The optional third argument C<lru_skip> (0-99) enables approximate LRU:
only every Nth access promotes the entry, skipping the linked-list update
the rest of the time. The tail entry (eviction candidate) is always
promoted to prevent starvation. This trades eviction precision for speed
on read-heavy workloads with hot keys (Zipf-like access patterns).

    lru_skip=0    strict LRU (default)
    lru_skip=90   promote every 10th access --good balance
    lru_skip=99   promote every 100th access --near-zero overhead

Recommended value for caching workloads: B<90>.

=head2 TTL expiry

When C<default_ttl> is set (in seconds), entries expire lazily: expired
entries are removed on access (C<get>, C<exists>, counter ops) and
skipped during iteration (C<keys>, C<values>, C<items>, C<each>, C<to_hash>). Note that
C<hm_xx_size> returns the count of all inserted entries including those
past their TTL that have not yet been lazily removed. C<exists> does not
promote entries in LRU mode (read-only check). C<get_or_set> inserts
with the map's default TTL; per-key TTL is not supported via C<get_or_set>
(use C<put_ttl> for that).

Individual entries can also be given a per-key TTL via C<hm_xx_put_ttl>
or C<< $map->put_ttl($key, $value, $seconds) >>, even on maps created
without a default TTL. The expires array is lazily allocated on first use.

Both features use parallel arrays indexed by slot, keeping the core
node struct unchanged. Maps created without LRU/TTL have zero overhead
beyond a never-taken branch.

=head1 PERFORMANCE

Benchmarks with 100k entries on Linux x86_64 (higher is better):

    INSERT (iterations/sec):
              Rate perl_ss perl_ii    SA    SS    IA  I32A  SI32   SI   IS I32S  I32   II I16S SI16 I16A  I16
    perl_ss 17.6/s      --     -1%  -11%  -27%  -45%  -48%  -51% -53% -54% -55% -83% -83% -86% -86% -88% -96%
    perl_ii 17.7/s      1%      --  -11%  -26%  -45%  -48%  -51% -53% -54% -54% -82% -83% -86% -86% -87% -96%
    SA      19.8/s     12%     12%    --  -18%  -38%  -42%  -45% -47% -48% -49% -80% -81% -84% -84% -86% -95%
    SS      24.1/s     37%     36%   22%    --  -25%  -29%  -33% -36% -37% -38% -76% -77% -81% -81% -83% -94%
    IA      32.0/s     82%     81%   62%   33%    --   -6%  -11% -15% -16% -17% -68% -70% -75% -75% -77% -92%
    I32A    34.0/s     93%     92%   72%   41%    6%    --   -5% -10% -11% -13% -66% -68% -73% -73% -76% -92%
    SI32    35.9/s    104%    103%   81%   49%   12%    6%    --  -5%  -6%  -8% -64% -66% -72% -72% -75% -91%
    SI      37.6/s    113%    112%   90%   56%   17%   11%    5%   --  -2%  -3% -63% -65% -70% -70% -73% -91%
    IS      38.3/s    118%    116%   93%   59%   20%   13%    7%   2%   --  -1% -62% -64% -70% -70% -73% -91%
    I32S    38.8/s    121%    119%   96%   61%   21%   14%    8%   3%   1%   -- -61% -63% -69% -69% -73% -90%
    I32      101/s    472%    468%  408%  318%  214%  196%  180% 168% 163% 159%   --  -5% -20% -20% -29% -75%
    II       106/s    501%    498%  435%  339%  230%  212%  195% 182% 176% 173%   5%   -- -16% -16% -25% -74%
    I16S     126/s    618%    614%  538%  425%  295%  272%  252% 236% 230% 226%  26%  19%   --  -0% -11% -69%
    SI16     126/s    618%    614%  538%  425%  295%  272%  252% 236% 230% 226%  26%  19%   0%   -- -11% -69%
    I16A     141/s    703%    698%  614%  487%  341%  316%  294% 276% 269% 264%  40%  34%  12%  12%   -- -65%
    I16      404/s   2196%   2182% 1941% 1577% 1161% 1090% 1027% 976% 955% 941% 302% 282% 220% 220% 186%   --

    LOOKUP (iterations/sec):
                Rate SS_direct perl_ii    SS    SA perl_ss   SI SI32   IS I32S I32A IS_direct   IA   II  I32 SI16 I16A I16S  I16
    SS_direct 26.0/s        --    -15%  -17%  -18%    -21% -30% -31% -43% -49% -54%      -54% -60% -68% -76% -84% -86% -90% -93%
    perl_ii   30.5/s       17%      --   -2%   -4%     -8% -18% -19% -34% -40% -46%      -47% -53% -62% -72% -81% -84% -88% -92%
    SS        31.3/s       20%      3%    --   -1%     -6% -16% -16% -32% -38% -44%      -45% -52% -61% -72% -81% -83% -88% -92%
    SA        31.7/s       22%      4%    1%    --     -4% -15% -15% -31% -38% -44%      -45% -51% -61% -71% -80% -83% -88% -92%
    perl_ss   33.1/s       27%      9%    6%    5%      -- -11% -12% -28% -35% -41%      -42% -49% -59% -70% -79% -82% -87% -91%
    SI        37.2/s       43%     22%   19%   17%     12%   --  -1% -19% -27% -34%      -35% -43% -54% -66% -77% -80% -85% -90%
    SI32      37.5/s       44%     23%   20%   18%     13%   1%   -- -19% -26% -33%      -34% -42% -54% -66% -77% -80% -85% -90%
    IS        46.0/s       77%     51%   47%   45%     39%  24%  23%   --  -9% -18%      -20% -29% -43% -58% -71% -75% -82% -88%
    I32S      50.7/s       95%     66%   62%   60%     53%  36%  35%  10%   -- -10%      -11% -22% -37% -54% -69% -73% -80% -86%
    I32A      56.3/s      116%     85%   80%   78%     70%  51%  50%  22%  11%   --       -2% -13% -30% -49% -65% -70% -78% -85%
    IS_direct 57.2/s      120%     87%   83%   80%     73%  54%  53%  24%  13%   2%        -- -12% -29% -48% -65% -69% -78% -85%
    IA        64.7/s      149%    112%  107%  104%     95%  74%  73%  41%  28%  15%       13%   -- -20% -42% -60% -65% -75% -83%
    II        80.8/s      210%    165%  158%  155%    144% 117% 116%  76%  59%  43%       41%  25%   -- -27% -50% -57% -68% -78%
    I32        111/s      325%    263%  254%  249%    234% 198% 196% 141% 118%  97%       94%  71%  37%   -- -31% -41% -57% -71%
    SI16       161/s      520%    428%  415%  409%    387% 334% 331% 250% 218% 186%      182% 149% 100%  46%   -- -13% -37% -57%
    I16A       186/s      615%    510%  495%  487%    462% 401% 397% 305% 267% 231%      226% 188% 130%  68%  15%   -- -27% -50%
    I16S       256/s      885%    740%  719%  709%    674% 589% 584% 457% 405% 355%      348% 296% 217% 132%  59%  38%   -- -32%
    I16        375/s     1342%   1130% 1100% 1084%   1033% 910% 902% 716% 640% 566%      556% 480% 365% 239% 133% 102%  46%   --

    INCREMENT (iterations/sec):
              Rate perl_ss perl_ii    SI32      SI     I32      II    SI16     I16
    perl_ss 26.2/s      --     -5%    -12%    -15%    -64%    -65%    -77%    -90%
    perl_ii 27.6/s      5%      --     -8%    -10%    -62%    -63%    -76%    -89%
    SI32    30.0/s     14%      9%      --     -3%    -59%    -60%    -73%    -88%
    SI      30.7/s     17%     12%      3%      --    -58%    -59%    -73%    -88%
    I32     73.1/s    179%    165%    144%    138%      --     -2%    -35%    -71%
    II      74.4/s    184%    170%    148%    142%      2%      --    -34%    -71%
    SI16     113/s    330%    310%    277%    267%     54%     52%      --    -56%
    I16      255/s    871%    824%    750%    728%    248%    242%    126%      --

    DELETE (iterations/sec):
              Rate    SA    SS    IS  SI32    SI perl_ss I32S   IA perl_ii I32A   II  I32 SI16 I16A I16S  I16
    SA      10.9/s    --   -6%  -18%  -25%  -25%    -27% -32% -32%    -36% -41% -58% -76% -83% -84% -86% -93%
    SS      11.6/s    6%    --  -13%  -20%  -21%    -22% -27% -28%    -32% -37% -55% -74% -82% -83% -85% -93%
    IS      13.3/s   22%   14%    --   -9%   -9%    -11% -17% -17%    -23% -28% -48% -70% -80% -81% -83% -92%
    SI32    14.6/s   33%   25%    9%    --   -0%     -2%  -9% -10%    -15% -21% -44% -68% -78% -79% -81% -91%
    SI      14.6/s   34%   26%   10%    0%    --     -2%  -8%  -9%    -15% -21% -43% -68% -78% -79% -81% -91%
    perl_ss 14.9/s   36%   28%   12%    2%    2%      --  -7%  -8%    -13% -19% -42% -67% -77% -78% -81% -91%
    I32S    16.0/s   46%   37%   20%   10%    9%      7%   --  -1%     -7% -14% -38% -65% -76% -77% -80% -90%
    IA      16.1/s   47%   38%   21%   11%   10%      8%   1%   --     -6% -13% -38% -64% -76% -76% -79% -90%
    perl_ii 17.2/s   57%   48%   29%   18%   18%     16%   8%   7%      --  -7% -33% -62% -74% -75% -78% -90%
    I32A    18.5/s   69%   59%   39%   27%   26%     24%  16%  15%      7%   -- -28% -59% -72% -73% -76% -89%
    II      25.8/s  136%  122%   94%   77%   77%     73%  62%  60%     50%  40%   -- -43% -61% -62% -67% -84%
    I32     45.1/s  313%  288%  239%  210%  208%    203% 182% 180%    162% 144%  75%   -- -32% -34% -42% -73%
    SI16    65.9/s  503%  467%  395%  353%  351%    343% 313% 310%    283% 257% 155%  46%   --  -3% -15% -60%
    I16A    68.3/s  525%  487%  413%  369%  367%    359% 328% 324%    297% 270% 164%  51%   4%   -- -12% -58%
    I16S    78.0/s  614%  571%  486%  436%  433%    424% 388% 384%    353% 322% 202%  73%  18%  14%   -- -53%
    I16      165/s 1406% 1315% 1136% 1030% 1025%   1005% 930% 922%    856% 791% 537% 265% 150% 141% 111%   --

=head2 LRU / TTL overhead

LRU and TTL add parallel arrays for linked-list pointers and expiry timestamps.
Maps created without these features have zero overhead beyond a never-taken branch.

    INSERT, II variant (iterations/sec):
                 Rate     II_lru II_lru_ttl         II
    II_lru     68.8/s         --        -2%       -16%
    II_lru_ttl 70.4/s         2%         --       -14%
    II         81.9/s        19%        16%         --

    LOOKUP, II variant (iterations/sec):
                 Rate II_lru_ttl     II_lru         II
    II_lru_ttl 68.3/s         --       -14%       -33%
    II_lru     79.3/s        16%         --       -23%
    II          103/s        50%        29%         --

    LRU EVICTION CHURN: insert 100k into capacity 50k (iterations/sec):
                 Rate II_lru_ttl     II_lru
    II_lru_ttl 61.7/s         --       -13%
    II_lru     71.0/s        15%         --

=head2 Method vs keyword overhead

Keywords bypass Perl's method dispatch for maximum performance. Method calls
(C<< $map->get($key) >>) are convenient but slower:

    II variant, 100k operations (iterations/sec):
                    keyword    method    overhead
    LOOKUP          85.5/s    59.1/s       -31%
    INSERT          71.1/s    59.0/s       -17%

=head1 MEMORY

Memory usage with 1M entries (fork-isolated measurements):

    Variant       Memory       Bytes/entry   vs Perl hash
    -------       ------       -----------   ------------
    I16*           0.5 MB        16            10x less
    I32            29 MB         30            5.5x less
    II             45 MB         46            3.5x less
    I32S           73 MB         75            2.2x less
    IS             73 MB         75            2.2x less
    SI16           73 MB         75            2.2x less
    SI32           73 MB         75            2.2x less
    SI             73 MB         75            2.2x less
    I16A           0.5 MB        16            10x less
    I32A           92 MB         95            1.7x less
    IA             92 MB         95            1.7x less
    SS            121 MB        124            1.3x less
    SA            140 MB        144            1.1x less
    perl %h (int) 159 MB        163            (baseline)
    perl %h (str) 166 MB        170            (baseline)

    * I16/I16A/I16S measured at 30k entries (int16 key range limits max unique keys to ~65k)

=head2 LRU / TTL memory overhead

Overhead per entry for LRU (prev/next pointers) and TTL (expiry timestamp),
measured with 1M entries in fork-isolated processes.

    II variant (int64/int64):
    Variant        Bytes/entry   LRU overhead   +TTL overhead
    -------        -----------   ------------   -------------
    II                    46.4       -              -
    II_lru                67.3     +20.9 B          -
    II_lru_ttl            79.9       -            +12.6 B

    SS variant (string/string, various key+value sizes):
    Variant        Bytes/entry   LRU overhead   +TTL overhead
    -------        -----------   ------------   -------------
    SS  8B keys          123.9       -              -
    SS  8B lru           140.7     +16.8 B          -
    SS  8B lru+ttl       152.2       -            +11.5 B
    SS 16B keys          123.9       -              -
    SS 16B lru           140.7     +16.8 B          -
    SS 16B lru+ttl       152.2       -            +11.5 B
    SS 32B keys          155.9       -              -
    SS 32B lru           172.7     +16.8 B          -
    SS 32B lru+ttl       181.1       -             +8.4 B
    SS 64B keys          220.0       -              -
    SS 64B lru           236.7     +16.8 B          -
    SS 64B lru+ttl       245.1       -             +8.4 B

=head1 IMPLEMENTATION

=over

=item * Open addressing with linear probing

=item * xxHash v0.8.3 (XXH3_64bits) hash functions for both integer and string keys

=item * Automatic resize at 75% load factor

=item * Tombstone deletion with automatic compaction

=item * Raw C strings (no Perl SV overhead) for string storage

=item * UTF-8 flag packed into high bit of length fields; keys with different UTF-8 flags are treated as distinct even if bytes match

=item * Sentinel values for integer keys (INT_MIN, INT_MIN+1 are reserved and silently rejected). I16/I32 variants croak on out-of-range keys and values.

=item * C<each()> iterator resets if C<put>/C<remove>/C<incr>/C<get_or_set> triggers a resize or compaction; do not mutate the map during C<each()> iteration. In scalar context, C<< $map->each >> returns the key only; the keyword form C<hm_xx_each> always evaluates in list context (XS::Parse::Keyword limitation).

=item * Requires 64-bit Perl (C<use64bitint>); II/IS/IA/SI variants use int64 keys/values via IV

=item * C<get_direct> returns a B<read-only> SV pointing at the map's internal buffer (zero-copy, no malloc). The returned value must not be held past any map mutation (C<put>, C<remove>, C<clear>, or any operation that may resize). Safe for immediate use: comparisons, printing, passing to functions. Use C<get> (the default) when you need to store the value.

=item * C<freeze>/C<thaw> produces a native-endian binary format; frozen data is not portable between systems with different byte orders

=back

=head1 DEPENDENCIES

L<XS::Parse::Keyword> (>= 0.40)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
