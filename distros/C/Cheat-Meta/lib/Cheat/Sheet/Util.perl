#============================================================================#
# Cheat::Sheet::Util - Cheat sheet for utility modules
# =  Copyright 2011 Xiong Changnian <xiong@cpan.org>   =
# = Free Software = Artistic License 2.0 = NO WARRANTY =
#                                                               v0.0.5
# I only had a high school education and believe me,
# I had to cheat to get that. 
# --Sparky Anderson
#----------------------------------------------------------------------------#

use Scalar::Util;               # General-utility scalar subroutines
use Scalar::Util qw(
    weaken isweak reftype refaddr blessed isvstring readonly tainted 
    dualvar looks_like_number openhandle set_prototype 
);
    weaken $ref;            # $ref will not keep @$ref, %$ref, etc. from GC
                            # note: copies of weak refs are not weak
    $bool = isweak  $ref;       # true if $ref is a weak reference
    $type = reftype $ref;       # 'SCALAR', 'ARRAY', 'HASH', or undef
    $addr = refaddr $ref;       # machine address of $ref or undef
    $got  = blessed $ref;       # class of blessed ref or undef 
    $bool = isvstring $s;       # true if $s is a v-string
    $bool = readonly  $s;       # true if $s is a readonly scalar
    $bool = tainted   $s;       # true if $s is tainted
    $got  = dualvar $num, $string;      # $got is $num or $string in context 
    $bool = looks_like_number $n;       # true if $n can be a number
    $fh   = openhandle $t_fh;       # $h if $t_fh is a tied or open filehandle
    set_prototype $cref, $proto;        # sets prototype of &$cref to $proto
## Scalar::Util

use List::Util;                 # General-utility list subroutines
use List::Util qw( max maxstr min minstr first reduce shuffle sum );
    $got  = max    @a;          # returns item >  than all the rest
    $got  = maxstr @a;          # returns item gt than all the rest
    $got  = min    @a;          # returns item <  than all the rest
    $got  = minstr @a;          # returns item lt than all the rest
    $got  = first  {$_} @a;     # ~grep but returns only first true item 
    $got  = reduce { $bool?$a:$b } @a;  # returns one item; last man standing 
    $got  = sum @a;             # sum of all elements
    @gots = shuffle @a;         # pseudo-randomizes order of @a
    # "The following are additions that have been requested..."
    sub any { $_ && return 1 for @_; 0 };       # One argument is true
    sub all { $_ || return 0 for @_; 1 };       # All arguments are true
    sub none { $_ && return 0 for @_; 1 };      # All arguments are false
    sub notall { $_ || return 1 for @_; 0 };    # One argument is false
    sub true { scalar grep { $_ } @_ };         # How many elements are true
    sub false { scalar grep { !$_ } @_ };       # How many elements are false
## List::Util

use List::MoreUtils ':all';     # The stuff missing in List::Util
use List::MoreUtils qw(
    any all none notall true false firstidx first_index 
    lastidx last_index insert_after insert_after_string 
    apply after after_incl before before_incl indexes 
    firstval first_value lastval last_value each_array
    each_arrayref pairwise natatime mesh zip uniq minmax
);
    # These operators take a block (~grep), setting $_ to each item in @a
    # Your block should test $_ and return a $bool
    $bool  = any    {$_} @a;    # true if any test  is  true   (  $A ||  $B )
    $bool  = all    {$_} @a;    # true if all tests are true   (  $A &&  $B )
    $bool  = none   {$_} @a;    # true if all tests are false  ( !$A && !$B )
    $bool  = notall {$_} @a;    # true if any test  is  false  ( !$A || !$B )
    #   #   #   #   #   #   De Morgan's Laws:    #   #   #   #   #   #   #   # 
    # ( !$A && !$B ) == !(  $A || $B  ) and ( !$A || !$B ) == !(  $A &&  $B )
    # (  $A &&  $B ) == !( !$A || !$B ) and (  $A ||  $B ) == !( !$A && !$B )
    $count = true   {$_} @a;        # how many true tests
    $count = false  {$_} @a;        # how many false tests
    $got  = firstidx{$_} @a;        # first item with true test
    $got  = first_index             # ditto; alias firstidx
    $got  = lastidx {$_} @a;        # last item with true test
    $got  = last_index              # ditto; alias lastidx
    $got  = insert_after {$_} $v => @a;   # put $v in @a after first true test        
    $got  = insert_after_string $s, $v => @a;  # insert after first item eq $s
    @gots = apply       {$_} @a;    # ~ map but doesn't modify @a
    @gots = after       {$_} @a;    # ( c )    ~~ after       {/b/} (a, b, c)
    @gots = after_incl  {$_} @a;    # ( b, c ) ~~ after_incl  {/b/} (a, b, c)
    @gots = before      {$_} @a;    # ( a )    ~~ before      {/b/} (a, b, c)
    @gots = before_incl {$_} @a;    # ( a, b ) ~~ before_incl {/b/} (a, b, c)
    @gots = indexes     {$_} @a;    # ( 1 )    ~~ indexes     {/b/} (a, b, c)
    $got  = firstval    {$_} @a;    # ~List::Util::first() but -1 on fail
    $got  = first_value             # ditto; alias firstval
    $got  = lastval     {$_} @a;    # last item testing true
    $got  = last_value              # ditto; alias lastval
    $cref = each_array @a, @b, @c;  # creates an n-tuplewise iterator closure
    while ( my ($A, $B, $C) = $cref->() ) {     # returns empty list 
        # Your code here                        #   when all lists exhausted
    };
    $cref = each_arrayref @a, @b, @c;   # iterator returns refs to arg lists
    $cref = natatime $n, @a;    # creates $n-at-a-time iterator from one list
    @gots = pairwise    {$_} @a, @b;    # ~map over two arrays
    @gots = mesh @a, @b, @c;    # ( $a[0], $b[0], $c[0], $a[1], $b[1], $c[1] )
    @gots = zip  @a, @b, @c;    # ditto; alias mesh
    @gots = uniq @a;            # returns *only* unique elements
    ( $min, $max )  = minmax @a;    # ~( List::Util::min(@a), ::max(@a) )
    @refs = part { $p = f($_) } @a; # partitions @a into multiple lists
    # you return integer $p as index of @refs; @refs is a list of arrayrefs
## List::MoreUtils

use List::AllUtils qw( :all );  # Everything from List::Util, List::MoreUtils

use List::Compare;              # Compare elements of two or more lists
# This object-oriented module is highly orthogonal, 
#   so that nearly any selection or choice may be combined with any other. 
# Most methods are equally okay for ( just two ) or ( three or more ) lists; 
#   some will Carp if called inappropriately.
#                            === Options/Modes === 
#           Regular: (default) Two lists, sorted results, many method calls ok
#          Unsorted: Don't sort method results              ( faster ) 
#       Accelerated: Only one method call possible per $lc  ( faster )
#          Multiple: Three or more lists in constructor 
# ! (specify $ix to refer to a given list; default 0; omit for only two lists)
#         Seen-hash: Use hashrefs instead of arrayrefs: 
#   [ 11, 12, 14, 14, 14, 15 ] ~~ { 11 => 1, 12 => 1, 14 => 3, 15 => 1 }
#
    # Construct a work-object 
    my $lc = List::Compare->new(             \@a, \@b, @c );  # default
    my $lc = List::Compare->new( '-u',       \@a, \@b, @c );  # unsorted
    my $lc = List::Compare->new(       '-a', \@a, \@b, @c );  # accelerated
    my $lc = List::Compare->new( '-u', '-a', \@a, \@b, @c );  #! -u before -a
    # Wrap constructor arguments in a hashref
    my $lc = List::Compare->new({
        unsorted    => 1,
        accelerated => 1,
        lists       => [ \@a, \@b, @c ],
    });
    # Methods return lists of results
    @gots = $lc->get_intersection;          # found in each/both list(s)
    @gots = $lc->get_union;                 # found in any/either list
    @gots = $lc->get_bag;                   # ~get_union but also duplicates
    @gots = $lc->get_unique($ix);           # found only in list $ix
    @gots = $lc->get_complement($ix);       # not found in $ix, but elsewhere
    @gots = $lc->get_symmetric_difference;  # found in only one list
    $gots = $lc->get_intersection_ref;          # ~methods above but
    $gots = $lc->get_union_ref;                 #           returns \@gots
    $gots = $lc->get_bag_ref;                   #       "
    $gots = $lc->get_unique_ref($ix);           #       "
    $gots = $lc->get_complement_ref($ix);       #       "
    $gots = $lc->get_symmetric_difference_ref;  #       "
    # Methods return boolean truth      # ( $ixL, $ixR ) default to ( 0, 1 )
    $bool = $lc->is_LsubsetR( $ixL, $ixR );     # true if all L in R
    $bool = $lc->is_RsubsetL( $ixL, $ixR );     # true if all R in L
    $bool = $lc->is_LequivalentR( $ixL, $ixR ); # true if same items in L, R
    $bool = $lc->is_LdisjointR( $ixL, $ixR );   # true if no items in common
    # Methods return list of which lists ($ix) satisfying conditions
    @ixs  = $lc->is_member_which($string);      # some item in $ix eq $string
    @ixs  = $lc->are_members_which(\@strings);  # ~prev but eq any in @strings
    # Dump
    $lc->print_subset_chart;        # pretty-print tables showing some
    $lc->print_equivalence_chart;   #   relationships; row/col as $ix
# List::Compare

use Hash::Util;                 # Hash locking, key locking, value locking
use Hash::Util qw(
    lock_keys lock_keys_plus unlock_keys 
    lock_value unlock_value 
    lock_hash unlock_hash lock_hash_recurse unlock_hash_recurse
    hash_locked hidden_keys legal_keys all_keys 
);
    # Restrict %hash to a set of keys; can delete but can't add other keys
    \%hash = lock_keys     ( %hash );           # current keys %hash
    \%hash = lock_keys     ( %hash, @keys );    # @keys; subset of keys @hash
    \%hash = lock_keys_plus( %hash, @keys );    #        superset
    \%hash = unlock_keys   ( %hash );           # remove restrictions
    # Cannot alter value of $key but can delete the k/v pair
    \%hash = lock_value    ( %hash, $key );
    \%hash = unlock_value  ( %hash, $key );
    # Lock the whole %hash; can't add, delete, or change value at all
    \%hash = lock_hash              ( %hash );
    \%hash = unlock_hash            ( %hash );
    \%hash = lock_hash_recurse      ( %hash );  # HoHoH... only
    \%hash = unlock_hash_recurse    ( %hash );  #   ditto
    # Other functions...
    $bool  = hash_unlocked ( %hash );       # true if %hash is unlocked
    @keys  = legal_keys    ( %hash );       # list of keys allowed
    @keys  = hidden_keys   ( %hash );       # see docs; experimental feature
    \%hash = all_keys( %hash, @keys, @hidden );       # experimental feature
    # Just like Daddy but take hashref arguments
    \%hash = lock_ref_keys          ( \%hash );
    \%hash = lock_ref_keys          ( \%hash, @keys );
    \%hash = lock_ref_keys_plus     ( \%hash, @keys );
    \%hash = unlock_ref_keys        ( \%hash );
    \%hash = lock_ref_value         ( \%hash, $key );
    \%hash = unlock_ref_value       ( \%hash, $key );
    \%hash = lock_hashref           ( \%hash );
    \%hash = unlock_hashref         ( \%hash );
    \%hash = lock_hashref_recurse   ( \%hash );
    \%hash = unlock_hashref_recurse ( \%hash );
    $bool  = hash_ref_unlocked      ( \%hash );
    @keys  = legal_ref_keys         ( \%hash );
    @keys  = hidden_ref_keys        ( \%hash );
## Hash::Util

#============================================================================#
__END__
