package Data::HashMap;

use strict;
use warnings;

our $VERSION = '0.02';

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
    hm_xx_size $map                 # returns entry count (includes TTL-expired not yet reaped)

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
    hm_xx_put_ttl $map, $key, $val, $seconds   # insert with per-key TTL ($seconds=0 uses map default)
    hm_xx_get_or_set $map, $key, $default      # get existing or insert default

String-value variants (SS, IS, I32S, I16S) also provide:

    hm_xx_get_direct $map, $key   # zero-copy get (read-only, see CAVEATS)

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
              Rate perl_ss perl_ii    SA    SS  I32A    IA  SI32   SI I32S   IS   II  I32 I16A I16S SI16  I16
    perl_ss 16.1/s      --     -3%  -15%  -22%  -45%  -47%  -53% -54% -55% -58% -81% -82% -87% -87% -88% -96%
    perl_ii 16.7/s      3%      --  -13%  -19%  -44%  -45%  -51% -53% -54% -57% -80% -81% -87% -87% -87% -96%
    SA      19.1/s     18%     15%    --   -7%  -35%  -37%  -44% -46% -47% -50% -77% -78% -85% -85% -85% -95%
    SS      20.6/s     28%     24%    8%    --  -30%  -33%  -40% -42% -43% -47% -75% -77% -84% -84% -84% -95%
    I32A    29.6/s     83%     77%   55%   44%    --   -3%  -14% -16% -18% -23% -64% -67% -77% -77% -78% -92%
    IA      30.5/s     89%     83%   60%   48%    3%    --  -11% -14% -15% -21% -63% -65% -76% -76% -77% -92%
    SI32    34.3/s    113%    106%   80%   67%   16%   12%    --  -3%  -5% -11% -59% -61% -73% -73% -74% -91%
    SI      35.3/s    119%    112%   85%   71%   19%   16%    3%   --  -2%  -8% -58% -60% -72% -73% -73% -91%
    I32S    36.1/s    123%    116%   89%   75%   22%   18%    5%   2%   --  -6% -57% -59% -72% -72% -73% -91%
    IS      38.5/s    138%    131%  102%   87%   30%   26%   12%   9%   7%   -- -54% -56% -70% -70% -71% -90%
    II      83.1/s    414%    398%  335%  303%  181%  172%  142% 135% 130% 116%   --  -6% -35% -36% -37% -78%
    I32     88.3/s    447%    430%  362%  329%  199%  189%  157% 150% 145% 129%   6%   -- -31% -32% -33% -77%
    I16A     128/s    690%    666%  568%  519%  332%  318%  272% 262% 254% 231%  54%  45%   --  -1%  -3% -67%
    I16S     129/s    700%    675%  577%  527%  337%  323%  276% 266% 258% 235%  55%  46%   1%   --  -2% -66%
    SI16     131/s    714%    689%  589%  538%  345%  331%  283% 273% 264% 241%  58%  49%   3%   2%   -- -66%
    I16      383/s   2270%   2197% 1905% 1758% 1195% 1154% 1015% 985% 961% 894% 361% 334% 200% 196% 191%   --

    LOOKUP (iterations/sec):
                Rate    SS perl_ii SS_direct    SA perl_ss  SI32   SI   IS I32S IS_direct I32A   IA   II  I32 SI16 I16A I16S  I16
    SS        29.6/s    --     -4%       -5%   -8%    -10%  -15% -22% -38% -44%      -47% -47% -49% -69% -73% -83% -87% -89% -93%
    perl_ii   31.0/s    5%      --       -1%   -3%     -6%  -11% -18% -35% -42%      -44% -44% -46% -67% -72% -82% -86% -88% -92%
    SS_direct 31.2/s    5%      1%        --   -3%     -6%  -10% -18% -34% -42%      -44% -44% -46% -67% -72% -82% -86% -88% -92%
    SA        32.0/s    8%      3%        3%    --     -3%   -8% -15% -32% -40%      -42% -43% -44% -66% -71% -81% -85% -88% -92%
    perl_ss   33.0/s   12%      7%        6%    3%      --   -5% -13% -30% -38%      -41% -41% -43% -65% -70% -81% -85% -87% -92%
    SI32      34.7/s   17%     12%       11%    8%      5%    --  -8% -27% -35%      -37% -38% -40% -63% -69% -80% -84% -87% -92%
    SI        37.8/s   28%     22%       21%   18%     15%    9%   -- -20% -29%      -32% -32% -34% -60% -66% -78% -83% -85% -91%
    IS        47.4/s   60%     53%       52%   48%     44%   37%  25%   -- -11%      -15% -15% -18% -50% -57% -72% -79% -82% -88%
    I32S      53.3/s   80%     72%       71%   66%     61%   54%  41%  12%   --       -4%  -4%  -8% -43% -52% -69% -76% -79% -87%
    IS_direct 55.5/s   87%     79%       78%   73%     68%   60%  47%  17%   4%        --  -1%  -4% -41% -50% -67% -75% -79% -86%
    I32A      55.8/s   88%     80%       79%   74%     69%   61%  47%  18%   5%        1%   --  -3% -41% -49% -67% -75% -78% -86%
    IA        57.6/s   95%     86%       85%   80%     75%   66%  52%  22%   8%        4%   3%   -- -39% -48% -66% -74% -78% -86%
    II        94.1/s  218%    204%      202%  194%    185%  171% 149%  99%  77%       70%  69%  63%   -- -15% -44% -57% -64% -77%
    I32        110/s  273%    256%      254%  244%    234%  218% 192% 133% 107%       99%  98%  91%  17%   -- -35% -50% -57% -73%
    SI16       170/s  473%    448%      444%  429%    414%  389% 348% 258% 218%      206% 204% 194%  80%  54%   -- -23% -34% -58%
    I16A       221/s  645%    612%      608%  588%    568%  536% 483% 365% 314%      297% 295% 283% 134% 100%  30%   -- -15% -46%
    I16S       259/s  774%    735%      730%  707%    684%  645% 584% 446% 385%      366% 364% 349% 175% 135%  52%  17%   -- -37%
    I16        409/s 1281%   1219%     1211% 1175%   1138% 1078% 981% 762% 667%      636% 633% 609% 334% 271% 141%  85%  58%   --

    ITERATE with each() (iterations/sec):
              Rate perl_ss perl_ii   SA   SS I32A   IA   IS   SI   II  I32 I16A  I16
    perl_ss 37.7/s      --     -3% -12% -29% -36% -38% -47% -48% -62% -63% -88% -89%
    perl_ii 38.9/s      3%      --  -9% -27% -34% -36% -45% -46% -61% -62% -88% -89%
    SA      42.8/s     13%     10%   -- -19% -27% -30% -40% -41% -57% -58% -87% -88%
    SS      52.9/s     40%     36%  24%   -- -10% -13% -25% -27% -47% -48% -84% -85%
    I32A    59.0/s     56%     52%  38%  11%   --  -3% -17% -18% -41% -42% -82% -84%
    IA      61.0/s     62%     57%  43%  15%   3%   -- -14% -15% -39% -40% -81% -83%
    IS      71.0/s     88%     83%  66%  34%  20%  16%   --  -2% -29% -30% -78% -80%
    SI      72.1/s     91%     85%  69%  36%  22%  18%   2%   -- -28% -29% -78% -80%
    II       100/s    166%    158% 135%  90%  70%  65%  41%  39%   --  -2% -69% -72%
    I32      102/s    170%    162% 138%  93%  73%  67%  43%  41%   2%   -- -68% -72%
    I16A     323/s    757%    731% 655% 510% 448% 430% 355% 348% 222% 217%   -- -10%
    I16      358/s    849%    820% 737% 576% 507% 487% 404% 396% 257% 251%  11%   --

    ITERATE with keys() (iterations/sec):
              Rate perl_ss perl_ii      SS      SI      II     I32
    perl_ss 94.6/s      --     -2%    -31%    -43%    -75%    -76%
    perl_ii 96.9/s      2%      --    -29%    -41%    -75%    -76%
    SS       136/s     44%     41%      --    -17%    -64%    -66%
    SI       165/s     74%     70%     21%      --    -57%    -59%
    II       383/s    305%    295%    181%    132%      --     -4%
    I32      400/s    323%    313%    193%    143%      4%      --

    ITERATE with items() vs each-in-loop (iterations/sec):
                Rate perl_each   perl_kv   SS_each  SS_items   II_each  II_items
    perl_each 39.3/s        --       -7%      -24%      -49%      -59%      -82%
    perl_kv   42.4/s        8%        --      -18%      -45%      -56%      -80%
    SS_each   51.5/s       31%       22%        --      -33%      -47%      -76%
    SS_items  76.9/s       96%       81%       49%        --      -21%      -64%
    II_each   96.8/s      146%      128%       88%       26%        --      -55%
    II_items   215/s      448%      408%      318%      180%      123%        --

    INCREMENT (iterations/sec):
              Rate perl_ss perl_ii    SI32      SI      II     I32    SI16     I16
    perl_ss 28.4/s      --    -10%    -21%    -22%    -67%    -70%    -78%    -92%
    perl_ii 31.5/s     11%      --    -12%    -13%    -63%    -66%    -76%    -91%
    SI32    35.9/s     26%     14%      --     -1%    -58%    -62%    -72%    -90%
    SI      36.2/s     27%     15%      1%      --    -58%    -61%    -72%    -89%
    II      85.9/s    202%    173%    139%    137%      --     -9%    -34%    -75%
    I32     94.0/s    231%    198%    162%    160%      9%      --    -27%    -73%
    SI16     130/s    356%    312%    261%    258%     51%     38%      --    -62%
    I16      343/s   1109%    990%    857%    849%    300%    265%    165%      --

    DELETE (iterations/sec):
              Rate    SS    SA SI32 perl_ss   SI perl_ii   IS I32S   IA I32A   II  I32 SI16 I16A I16S  I16
    SS      11.9/s    --   -1% -24%    -28% -29%    -34% -37% -39% -44% -44% -68% -75% -85% -86% -87% -93%
    SA      12.1/s    1%    -- -23%    -27% -28%    -33% -36% -38% -43% -43% -67% -75% -85% -85% -87% -93%
    SI32    15.7/s   32%   30%   --     -5%  -6%    -13% -17% -20% -26% -26% -57% -67% -80% -81% -82% -91%
    perl_ss 16.6/s   40%   38%   6%      --  -0%     -8% -12% -15% -22% -22% -55% -66% -79% -80% -81% -90%
    SI      16.7/s   40%   38%   6%      0%   --     -8% -12% -15% -21% -22% -55% -66% -79% -80% -81% -90%
    perl_ii 18.1/s   52%   50%  15%      9%   9%      --  -4%  -8% -15% -15% -51% -62% -77% -78% -80% -89%
    IS      18.9/s   59%   57%  20%     14%  13%      4%   --  -4% -11% -11% -49% -61% -76% -77% -79% -89%
    I32S    19.6/s   65%   63%  25%     18%  18%      8%   4%   --  -8%  -8% -47% -59% -75% -76% -78% -89%
    IA      21.2/s   78%   76%  35%     28%  27%     17%  12%   8%   --  -1% -42% -56% -73% -74% -76% -88%
    I32A    21.3/s   79%   77%  36%     28%  28%     18%  13%   9%   1%   -- -42% -56% -73% -74% -76% -88%
    II      36.9/s  210%  206% 135%    122% 121%    104%  95%  88%  74%  73%   -- -24% -53% -55% -59% -79%
    I32     48.3/s  306%  301% 208%    191% 190%    167% 156% 147% 128% 127%  31%   -- -38% -41% -46% -72%
    SI16    78.0/s  555%  546% 396%    369% 368%    330% 313% 298% 267% 266% 111%  61%   --  -5% -13% -55%
    I16A    82.1/s  590%  581% 423%    394% 393%    353% 335% 319% 287% 285% 123%  70%   5%   --  -8% -52%
    I16S    89.5/s  652%  642% 470%    439% 437%    394% 374% 357% 322% 320% 143%  85%  15%   9%   -- -48%
    I16      172/s 1348% 1328% 997%    937% 934%    850% 812% 779% 712% 708% 367% 256% 121% 110%  92%   --

=head2 LRU / TTL overhead

LRU and TTL add parallel arrays for linked-list pointers and expiry timestamps.
Maps created without these features have zero overhead beyond a never-taken branch.

    INSERT, II variant (iterations/sec):
                 Rate     II_lru II_lru_ttl         II
    II_lru     59.5/s         --        -2%       -13%
    II_lru_ttl 60.7/s         2%         --       -11%
    II         68.5/s        15%        13%         --

    LOOKUP, II variant (iterations/sec):
                 Rate     II_lru II_lru_ttl         II
    II_lru     70.3/s         --        -2%       -19%
    II_lru_ttl 71.6/s         2%         --       -18%
    II         87.2/s        24%        22%         --

    LRU EVICTION CHURN: insert 100k into capacity 50k (iterations/sec):
                 Rate II_lru_ttl     II_lru
    II_lru_ttl 71.9/s         --        -5%
    II_lru     76.0/s         6%         --

=head2 Method vs keyword overhead

Keywords bypass Perl's method dispatch for maximum performance. Method calls
(C<< $map->get($key) >>) are convenient but slower:

    II variant, 100k operations (iterations/sec):
                    keyword    method    overhead
    LOOKUP           101/s    81.4/s       -20%
    INSERT          82.8/s    72.3/s       -13%

=head1 MEMORY

Memory usage with 1M entries (fork-isolated measurements):

    Variant       Memory       Bytes/entry   vs Perl hash
    -------       ------       -----------   ------------
    I16*           0.5 MB        16            10x less
    I32            28 MB         30            5.5x less
    II             44 MB         46            3.5x less
    I32S           72 MB         75            2.2x less
    IS             72 MB         75            2.2x less
    SI16           72 MB         75            2.2x less
    SI32           72 MB         75            2.2x less
    SI             72 MB         75            2.2x less
    I16A           0.5 MB        16            10x less
    I32A           90 MB         95            1.7x less
    IA             90 MB         95            1.7x less
    SS            118 MB        124            1.3x less
    SA            137 MB        144            1.1x less
    perl %h (int) 155 MB        163            (baseline)
    perl %h (str) 162 MB        170            (baseline)

    * I16/I16A measured at 30k entries (int16 key range limits max unique keys to ~65k)

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

=item * UTF-8 flag packed into high bit of length fields

=item * Sentinel values for integer keys (INT_MIN, INT_MIN+1 are reserved and silently rejected)

=item * C<each()> iterator resets if C<put>/C<remove>/C<incr>/C<get_or_set> triggers a resize or compaction; do not mutate the map during C<each()> iteration

=item * Requires 64-bit Perl (C<use64bitint>); II/IS/IA/SI variants use int64 keys/values via IV

=item * C<get_direct> returns a B<read-only> SV pointing at the map's internal buffer (zero-copy, no malloc). The returned value must not be held past any map mutation (C<put>, C<remove>, C<clear>, or any operation that may resize). Safe for immediate use: comparisons, printing, passing to functions. Use C<get> (the default) when you need to store the value.

=back

=head1 DEPENDENCIES

L<XS::Parse::Keyword> (>= 0.40)

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
