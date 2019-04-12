use strict;
use warnings;

use Test::More tests => 2+5+3;
use Code::DRY;
#########################
can_ok('Code::DRY', 'set_lcp_to_zero_for_shadowed_substrings');
can_ok('Code::DRY', 'find_duplicates_in');

##TODO: {

##local $TODO = 'more research needed for substring filtering';
# create a memory file
my $teststring = 'missssissssippi';

#sa  offset
# p map { (my $s=substr($teststring, Code::DRY::get_offset_at($_)))=~s{\n}{\\n}g; sprintf "#%2d  %2d %s\n",$_,Code::DRY::get_offset_at($_),$s } (0..Code::DRY::get_size()-1)
# 0  14 i                              (i)
# 1  11 ippi                        (i)
# 2   6 issssippi              (issss)
# 3   1 issssissssippi    (issss)
# 4   0 missssissssippi  (m)
# 5  13 pi                           (p)
# 6  12 ppi                           (p)
# 7  10 sippi                      (s)
# 8   5 sissssippi            (s)
# 9   9 ssippi                    (s)
#10   4 ssissssippi          (s)
#11   8 sssippi                  (s)
#12   3 sssissssippi        (s)
#13   7 ssssippi                (s)
#14   2 ssssissssippi      (s)

#lcp offset
# p map { (my $s=substr($teststring, Code::DRY::get_offset_at($_), Code::DRY::get_len_at($_)))=~s{\n}{\\n}g; sprintf "#%2d  %2d (%s)\n",$_,Code::DRY::get_len_at($_),$s } (0..Code::DRY::get_size()-1)
# 0   0 ()           -> @14/0 (--,--)          5: @13/>0?      
# 1   1 (i)          -> @11/1 (11,11) (14,14)  7: @10/>=1? || @13/>=1 not shadowed because @10/0 || @13/0
# 2   1 (i)          -> @6/1  ( 6, 6) (11,11)  8:  @5/>=1? || @10/>=1     shadowed because @5/2  || @10/0
# 3   6 (issssi)     -> @1/6  ( 1, 6) ( 6,11)  4:  @0/>=6? || @5/>=6  not shadowed because @0/0  || @5/2
# 4   0 ()           -> @0/0  (--,--)                          shadowed per definition for first offset
# 5   0 ()           -> @13/0 (--,--)          6: @12/>0?
# 6   1 (p)          -> @12/1 (12,12) (13,13)  1: @11/>=1? not shadowed because @11/1
# 7   0 ()           -> @10/0 (--,--)          9:  @9/>0?      
# 8   2 (si)         -> @5/2  ( 5, 6) (10,11) 10:  @4/>=2? || @9/>=2      shadowed because @4/3  || @9/1
# 9   1 (s)          -> @9/1  ( 9, 9) ( 5, 5) 11:  @8/>=1? || @4/>=1      shadowed because @8/2  || @4/3
#10   3 (ssi)        -> @4/3  ( 4, 6) ( 9,11) 12:  @3/>=3? || @8/>=3      shadowed because @3/4  || @8/2
#11   2 (ss)         -> @8/2  ( 8, 9) ( 4, 5) 13:  @7/>=2? || @3/>=2      shadowed because @7/3  || @3/4
#12   4 (sssi)       -> @3/4  ( 3, 6) ( 8,11) 14:  @2/>=4? || @7/>=4      shadowed because @2/5  || @7/3
#13   3 (sss)        -> @7/3  ( 7, 9) ( 3, 5)  2:  @6/>=3? || @4/>=3      shadowed because @6/1  || @4/3
#14   5 (ssssi)	     -> @2/5  ( 2, 6) ( 7,11)  3:  @1/>=5? || @6/>=5      shadowed because @1/5  || @6/1

#isa index (inverted suffix array)
# p map { (my $s=substr($teststring, Code::DRY::get_offset_at(Code::DRY::get_isa_at($_))))=~s{\n}{\\n}g; sprintf "#%2d  %2d %s\n",$_,Code::DRY::get_isa_at($_),$s } (0..Code::DRY::get_size()-1)
# 
# 0   4 missssissssippi 0 ()           @0/0  (--,--)
# 1   3 issssissssippi  5 (issss)      @1/5  ( 1, 5) ( 6,10)
# 2  14 ssssissssippi   5 (ssssi)      @2/5  ( 2, 6) ( 7,11) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 3  12 sssissssippi    4 (sssi)       @3/4  ( 3, 6) ( 8,11) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 4  10 ssissssippi     3 (ssi)        @4/3  ( 4, 6) ( 9,11) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 5   8 sissssippi      2 (si)         @5/2  ( 5, 6) (10,11) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 6   2 issssippi       1 (i)          @6/1  ( 6, 6) (11,11) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 7  13 ssssippi        3 (sss)        @7/3  ( 7, 9) ( 3, 5) cancel, if previous entry has same or greater lcp and same reference group => is part of 3 ???
# 8  11 sssippi         2 (ss)         @8/2  ( 8, 9) ( 4, 5) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
# 9   9 ssippi          1 (s)          @9/1  ( 9, 9) ( 5, 5) cancel, if previous entry has same or greater lcp and same reference group => is part of 3
#10   7 sippi           0 ()           @10/0 (--,--)
#11   1 ippi            1 (i)          @11/1 (11,11) (14,14)
#12   6 ppi             1 (p)          @12/1 (12,12) (13,13)
#13   5 pi              0 ()           @13/0 (--,--)
#14   0 i               0 ()           @14/0 (--,--)

Code::DRY::build_suffixarray_and_lcp($teststring);
is_deeply([14,11,6,1,0,13,12,10,5,9,4,8,3,7,2], [ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)],
  "build_suffixarray_and_lcp() builds suffix array");
is_deeply([0,1,1,6,0,0,1,0,2,1,3,2,4,3,5], [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
  "build_suffixarray_and_lcp() builds lcp array");
Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
is_deeply([0,1,1,5,0,0,1,0,2,1,3,2,4,3,5], [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
  "set_lcp_to_zero_for_shadowed_substrings() sets all shadowed prefixes to zero length");
Code::DRY::set_lcp_to_zero_for_shadowed_substrings();
is_deeply([0,1,0,5,0,0,1,0,0,0,0,0,0,3,0], [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
  "set_lcp_to_zero_for_shadowed_substrings() sets all shadowed prefixes to zero length");
is_deeply([4,3,14,12,10,8,2,13,11,9,7,1,6,5,0], [ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)],
  "build_suffixarray_and_lcp() builds inverse suffix array");

my @files = ($teststring);
my @filerefs = map { \$_ } @files;

#TODO

@filerefs = map { \$_ } ("1234", "1235", "235");
$teststring = join '', map { ${$_} } @filerefs;
Code::DRY::enter_files(\@filerefs);
Code::DRY::build_suffixarray_and_lcp($teststring);
Code::DRY::clip_lcp_to_fileboundaries(\@Code::DRY::fileoffsets);
Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
Code::DRY::set_lcp_to_zero_for_shadowed_substrings();
is_deeply([0,4,1,8,5,2,9,6,3,10,7], [ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)],
  "build_suffixarray_and_lcp() builds suffix array");
#remove_shadow substrings
#isa ordering
# 0   0 12341235235 0 ()    @0/0  (--,--)
# 1   2 2341235235  0 ()    @1/0  (--,--)
# 2   5 341235235   0 ()    @2/0  (--,--)
# 3   8 41235235    0 ()    @3/0  (--,--)
# 4   1 1235235     3 (123) @4/3  ( 4, 6) ( 0, 2)
# 5   4 235235      3 (235) @5/3  ( 5, 7) ( 8,10)
# 6   7 35235       2 (35)  @6/2  ( 6, 7) ( 9,10) cancel, is part of 4
# 7  10 5235        1 (5)   @7/1  ( 7, 7) (10,10) cancel, is part of 7
# 8   3 235         2 (23)  @8/2  ( 8, 9) ( 1, 2) cancel, is part of longer 1 and 4 problem
# 9   6 35          1 (3)   @9/1  ( 9, 9) ( 2, 2) cancel, is part of 3
#10   9 5           0 ()    @10/0 (--,--)
is_deeply([0,3,0,2,3,0,0,0,0,0,0], [ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
  "set_lcp_to_zero_for_shadowed_substrings() sets all shadowed prefixes to zero length");
is_deeply([0,2,5,8,1,4,7,10,3,6,9], [ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)],
  "build_suffixarray_and_lcp() builds inverse suffix array");

#Code::DRY::find_duplicates_in(-1, undef, @filerefs);
@filerefs = map { \$_ } ("1234", "1235", "1236", "1237", "1238", "1239");
$teststring = join '', map { ${$_} } @filerefs;
Code::DRY::enter_files(\@filerefs);
Code::DRY::build_suffixarray_and_lcp($teststring);
Code::DRY::clip_lcp_to_fileboundaries(\@Code::DRY::fileoffsets);
Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
Code::DRY::set_lcp_to_zero_for_shadowed_substrings();
Code::DRY::find_duplicates_in(-1, undef, @filerefs);

##}
