#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 64;
use Array::Each;

# Testing parms combos (see the __END__ for combos list)
# Note, _each not included here, other than its being automatically
#       set based on the values of the other attributes.
# Note, see test 08-AE-count_combos for parms combos that include count

# go: create a test string using parm combo
use constant NOWARN=>0;
sub go {
    my( $t, $n, $warn ) = @_;
    $n ||= 1;  # num loops
    $warn = defined $warn ? $warn : 1;
    local $" = '';
    my $r = '';
    if( $warn ) {
        for(1..$n){while(my(@a)=$t->each){$r.=">@a"}}}
    else { no warnings 'uninitialized';
        for(1..$n){while(my(@a)=$t->each){$r.=">@a"}}}
    $r;
}

my @x = qw( a b c d e );
my @y = ( 1..9 );
my( $t, $r );

#  1. 1-set 
$t = Array::Each->new( set=>[\@x, \@y],
    );
is( go($t),
    '>a10>b21>c32>d43>e54',
    "combo 1. 1" );

#  2. 1-set 2-iterator 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1,
    );
is( go($t),
    '>b21>c32>d43>e54',
    "combo 2. 1 2" );

#  3. 1-set 2-iterator 3-rewind 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1,
    );
is( go($t,2),
    '>b21>c32>d43>e54>b21>c32>d43>e54',
    "combo 3. 1 2 3" );

#  4. 1-set 2-iterator 3-rewind 4-bound 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>2, bound=>0,
    );
is( go($t,2,NOWARN),
    '>c32>d43>e54>65>76>87>98>c32>d43>e54>65>76>87>98',
    "combo 4. 1 2 3 4" );

#  5. 1-set 2-iterator 3-rewind 4-bound 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>3, rewind=>3, bound=>0, undef=>'_',
    );
is( go($t,2),
    '>d43>e54>_65>_76>_87>_98>d43>e54>_65>_76>_87>_98',
    "combo 5. 1 2 3 4 5" );

#  6. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>4, rewind=>4, bound=>0, undef=>'_', stop=>7,
    );
is( go($t,2),
    '>e54>_65>_76>_87>e54>_65>_76>_87',
    "combo 6. 1 2 3 4 5 6" );

#  7. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, undef=>'_', stop=>6, group=>2,
    );
is( go($t,2),
    '>cd342>e_564>__786>de453>__675',
    "combo 7. 1 2 3 4 5 6 7" );

#  8. 1-set 2-iterator 3-rewind 4-bound 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, bound=>0, undef=>'_', group=>3,
    );
is( go($t,2),
    '>bcd2341>e__5674>___89_7>bcd2341>e__5674>___89_7',
    "combo 8. 1 2 3 4 5 7" );

#  9. 1-set 2-iterator 3-rewind 4-bound 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>2, bound=>0, stop=>6,
    );
is( go($t,2,NOWARN),
    '>c32>d43>e54>65>76>c32>d43>e54>65>76',
    "combo 9. 1 2 3 4 6" );

# 10. 1-set 2-iterator 3-rewind 4-bound 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>0, rewind=>0, bound=>0, stop=>3, group=>3,
    );
is( go($t,2,NOWARN),
    '>abc1230>de4563>abc1230>de4563',
    "combo 10. 1 2 3 4 6 7" );

# 11. 1-set 2-iterator 3-rewind 4-bound 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>0, rewind=>0, bound=>0, group=>3,
    );
is( go($t,2,NOWARN),
    '>abc1230>de4563>7896>abc1230>de4563>7896',
    "combo 11. 1 2 3 4 7" );

# 12. 1-set 2-iterator 3-rewind 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>0, rewind=>0, undef=>'_',
    );
is( go($t,2),
    '>a10>b21>c32>d43>e54>a10>b21>c32>d43>e54',
    "combo 12. 1 2 3 5" );

# 13. 1-set 2-iterator 3-rewind 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, undef=>'_', stop=>3,
    );
is( go($t,2),
    '>b21>c32>d43>b21>c32>d43',
    "combo 13. 1 2 3 5 6" );

# 14. 1-set 2-iterator 3-rewind 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, undef=>'_', stop=>2, group=>2,
    );
is( go($t,2),
    '>bc231>bc231',
    "combo 14. 1 2 3 5 6 7" );

# 15. 1-set 2-iterator 3-rewind 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, undef=>'_', group=>2,
    );
is( go($t,2),
    '>bc231>de453>bc231>de453',
    "combo 15. 1 2 3 5 7" );

# 16. 1-set 2-iterator 3-rewind 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, stop=>3,
    );
is( go($t,2),
    '>b21>c32>d43>b21>c32>d43',
    "combo 16. 1 2 3 6" );

# 17. 1-set 2-iterator 3-rewind 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, stop=>2, group=>2,
    );
is( go($t,2),
    '>bc231>bc231',
    "combo 17. 1 2 3 6 7" );

# 18. 1-set 2-iterator 3-rewind 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, rewind=>1, group=>2,
    );
is( go($t,2),
    '>bc231>de453>bc231>de453',
    "combo 18. 1 2 3 7" );

# 19. 1-set 2-iterator 4-bound 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0,
    );
is( go($t,1,NOWARN),
    '>b21>c32>d43>e54>65>76>87>98',
    "combo 19. 1 2 4" );

# 20. 1-set 2-iterator 4-bound 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, undef=>'_',
    );
is( go($t,1),
    '>b21>c32>d43>e54>_65>_76>_87>_98',
    "combo 20. 1 2 4 5" );

# 21. 1-set 2-iterator 4-bound 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, undef=>'_', stop=>7,
    );
is( go($t,1),
    '>b21>c32>d43>e54>_65>_76>_87',
    "combo 21. 1 2 4 5 6" );

# 22. 1-set 2-iterator 4-bound 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, undef=>'_', stop=>6, group=>2,
    );
is( go($t,1),
    '>bc231>de453>__675',
    "combo 22. 1 2 4 5 6 7" );

# 23. 1-set 2-iterator 4-bound 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, undef=>'_', group=>2,
    );
is( go($t,1),
    '>bc231>de453>__675>__897',
    "combo 23. 1 2 4 5 7" );

# 24. 1-set 2-iterator 4-bound 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, stop=>6,
    );
is( go($t,1,NOWARN),
    '>b21>c32>d43>e54>65>76',
    "combo 24. 1 2 4 6" );

# 25. 1-set 2-iterator 4-bound 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, stop=>6, group=>2,
    );
is( go($t,1,NOWARN),
    '>bc231>de453>675',
    "combo 25. 1 2 4 6 7" );

# 26. 1-set 2-iterator 4-bound 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, bound=>0, group=>2,
    );
is( go($t,1,NOWARN),
    '>bc231>de453>675>897',
    "combo 26. 1 2 4 7" );

# 27. 1-set 2-iterator 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, undef=>'_',
    );
is( go($t,1),
    '>b21>c32>d43>e54',
    "combo 27. 1 2 5" );

# 28. 1-set 2-iterator 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, undef=>'_', stop=>3,
    );
is( go($t,1),
    '>b21>c32>d43',
    "combo 28. 1 2 5 6" );

# 29. 1-set 2-iterator 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>1, undef=>'_', stop=>1, group=>6,
    );
is( go($t,1),
    '>bcde__2345671',
    "combo 29. 1 2 5 6 7" );

# 30. 1-set 2-iterator 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, undef=>'_', group=>5,
    );
is( go($t,1),
    '>cde__345672',
    "combo 30. 1 2 5 7" );

# 31. 1-set 2-iterator 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, stop=>3,
    );
is( go($t,1),
    '>c32>d43',
    "combo 31. 1 2 6" );

# 32. 1-set 2-iterator 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, stop=>3, group=>2,
    );
is( go($t,1),
    '>cd342',
    "combo 32. 1 2 6 7" );

# 33. 1-set 2-iterator 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, group=>2,
    );
is( go($t,1,NOWARN),
    '>cd342>e564',
    "combo 33. 1 2 7" );

# 34. 1-set 3-rewind 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>1,
    );
is( go($t,2),
    '>a10>b21>c32>d43>e54>b21>c32>d43>e54',
    "combo 34. 1 3" );

# 35. 1-set 3-rewind 4-bound 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, bound=>0,
    );
is( go($t,2,NOWARN),
    '>a10>b21>c32>d43>e54>65>76>87>98>c32>d43>e54>65>76>87>98',
    "combo 35. 1 3 4" );

# 36. 1-set 3-rewind 4-bound 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_',
    );
is( go($t,2),
    '>a10>b21>c32>d43>e54>_65>_76>_87>_98>d43>e54>_65>_76>_87>_98',
    "combo 36. 1 3 4 5" );

# 37. 1-set 3-rewind 4-bound 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>4, bound=>0, undef=>'_', stop=>6,
    );
is( go($t,2),
    '>a10>b21>c32>d43>e54>_65>_76>e54>_65>_76',
    "combo 37. 1 3 4 5 6" );

# 38. 1-set 3-rewind 4-bound 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', stop=>6, group=>2,
    );
is( go($t,2),
    '>ab120>cd342>e_564>__786>de453>__675',
    "combo 38. 1 2 4 5 6 7" );

# 39. 1-set 3-rewind 4-bound 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', group=>2,
    );
is( go($t,2),
    '>ab120>cd342>e_564>__786>__9_8>de453>__675>__897',
    "combo 39. 1 3 4 5 7" );

# 40. 1-set 3-rewind 4-bound 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, bound=>0, stop=>3,
    );
is( go($t,2),
    '>a10>b21>c32>d43>c32>d43',
    "combo 40. 1 3 4 6" );

# 41. 1-set 3-rewind 4-bound 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, bound=>0, stop=>3, group=>3,
    );
is( go($t,2,NOWARN),
    '>abc1230>de4563>cde3452',
    "combo 41. 1 3 4 6 7" );

# 42. 1-set 3-rewind 4-bound 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, bound=>0, group=>3,
    );
is( go($t,2,NOWARN),
    '>abc1230>de4563>7896>cde3452>6785>98',
    "combo 42. 1 3 4 7" );

# 43. 1-set 3-rewind 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>4, undef=>'_',
    );
is( go($t,2),
    '>a10>b21>c32>d43>e54>e54',
    "combo 43. 1 3 5" );

# 44. 1-set 3-rewind 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', stop=>3,
    );
is( go($t,2),
    '>a10>b21>c32>d43>d43',
    "combo 44. 1 3 5 6" );

# 45. 1-set 3-rewind 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', stop=>3, group=>2,
    );
is( go($t,2),
    '>ab120>cd342>de453',
    "combo 45. 1 3 5 6 7" );

# 46. 1-set 3-rewind 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', stop=>3, group=>2,
    );
is( go($t,2),
    '>ab120>cd342>de453',
    "combo 46. 1 3 5 7" );

# 47. 1-set 3-rewind 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, stop=>2,
    );
is( go($t,2),
    '>a10>b21>c32>c32',
    "combo 47. 1 3 6" );

# 48. 1-set 3-rewind 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, stop=>3, group=>4,
    );
is( go($t,2,NOWARN),
    '>abcd12340>cde34562',
    "combo 48. 1 3 6 7" );

# 49. 1-set 3-rewind 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    rewind=>2, group=>4,
    );
is( go($t,2,NOWARN),
    '>abcd12340>e56784>cde34562',
    "combo 49. 1 3 7" );

# 50. 1-set 4-bound 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0,
    );
is( go($t,1,NOWARN),
    '>a10>b21>c32>d43>e54>65>76>87>98',
    "combo 50. 1 4" );

# 51. 1-set 4-bound 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_',
    );
is( go($t,1),
    '>a10>b21>c32>d43>e54>_65>_76>_87>_98',
    "combo 51. 1 4 5" );

# 52. 1-set 4-bound 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', stop=>6,
    );
is( go($t,1),
    '>a10>b21>c32>d43>e54>_65>_76',
    "combo 52. 1 4 5 6" );

# 53. 1-set 4-bound 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', stop=>5, group=>3
    );
is( go($t,1),
    '>abc1230>de_4563',
    "combo 53. 1 4 5 6 7" );

# 54. 1-set 4-bound 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', group=>3
    );
is( go($t,1),
    '>abc1230>de_4563>___7896',
    "combo 54. 1 4 5 7" );

# 55. 1-set 4-bound 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, stop=>10,
    );
is( go($t,1,NOWARN),
    '>a10>b21>c32>d43>e54>65>76>87>98>9>10',
    "combo 55. 1 4 6" );

# 56. 1-set 4-bound 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, stop=>10, group=>2,
    );
is( go($t,1,NOWARN),
    '>ab120>cd342>e564>786>98>10',
    "combo 56. 1 4 6 7" );

# 57. 1-set 4-bound 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    bound=>0, group=>2,
    );
is( go($t,1,NOWARN),
    '>ab120>cd342>e564>786>98',
    "combo 57. 1 4 7" );

# 58. 1-set 5-undef 
$t = Array::Each->new( set=>[\@x, \@y],
    undef=>'_',
    );
is( go($t,1),
    '>a10>b21>c32>d43>e54',
    "combo 58. 1 5" );

# 59. 1-set 5-undef 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', stop=>3,
    );
is( go($t,1),
    '>a10>b21>c32>d43',
    "combo 59. 1 5 6" );

# 60. 1-set 5-undef 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', stop=>3, group=>2,
    );
is( go($t,1),
    '>ab120>cd342',
    "combo 60. 1 5 6 7" );

# 61. 1-set 5-undef 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', group=>2,
    );
is( go($t,1),
    '>ab120>cd342>e_564',
    "combo 61. 1 5 7" );

# 62. 1-set 6-stop 
$t = Array::Each->new( set=>[\@x, \@y],
    stop=>3,
    );
is( go($t,1),
    '>a10>b21>c32>d43',
    "combo 62. 1 6" );

# 63. 1-set 6-stop 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    stop=>3, group=>2,
    );
is( go($t,1),
    '>ab120>cd342',
    "combo 63. 1 6 7" );

# 64. 1-set 7-group 
$t = Array::Each->new( set=>[\@x, \@y],
    group=>2,
    );
is( go($t,1,NOWARN),
    '>ab120>cd342>e564',
    "combo 64. 1 7" );

__END__
# generate possible combos of parms:

my @p = qw( 2-iterator 3-rewind 4-bound 5-undef 6-stop 7-group );
my @r; my $l = @p;
for( 0..2**$l-1 ) {
    my $x = ''; my $s = reverse sprintf "%0${l}b", $_;
    for( 0..6 ) { $x .= "$p[ $_ ] ", if substr( $s, $_, 1 ) }
    push @r, $x }
my $count; printf "%2d. 1-set $_\n", ++$count for sort @r;

# output:

 1. 1-set 
 2. 1-set 2-iterator 
 3. 1-set 2-iterator 3-rewind 
 4. 1-set 2-iterator 3-rewind 4-bound 
 5. 1-set 2-iterator 3-rewind 4-bound 5-undef 
 6. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 
 7. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 7-group 
 8. 1-set 2-iterator 3-rewind 4-bound 5-undef 7-group 
 9. 1-set 2-iterator 3-rewind 4-bound 6-stop 
10. 1-set 2-iterator 3-rewind 4-bound 6-stop 7-group 
11. 1-set 2-iterator 3-rewind 4-bound 7-group 
12. 1-set 2-iterator 3-rewind 5-undef 
13. 1-set 2-iterator 3-rewind 5-undef 6-stop 
14. 1-set 2-iterator 3-rewind 5-undef 6-stop 7-group 
15. 1-set 2-iterator 3-rewind 5-undef 7-group 
16. 1-set 2-iterator 3-rewind 6-stop 
17. 1-set 2-iterator 3-rewind 6-stop 7-group 
18. 1-set 2-iterator 3-rewind 7-group 
19. 1-set 2-iterator 4-bound 
20. 1-set 2-iterator 4-bound 5-undef 
21. 1-set 2-iterator 4-bound 5-undef 6-stop 
22. 1-set 2-iterator 4-bound 5-undef 6-stop 7-group 
23. 1-set 2-iterator 4-bound 5-undef 7-group 
24. 1-set 2-iterator 4-bound 6-stop 
25. 1-set 2-iterator 4-bound 6-stop 7-group 
26. 1-set 2-iterator 4-bound 7-group 
27. 1-set 2-iterator 5-undef 
28. 1-set 2-iterator 5-undef 6-stop 
29. 1-set 2-iterator 5-undef 6-stop 7-group 
30. 1-set 2-iterator 5-undef 7-group 
31. 1-set 2-iterator 6-stop 
32. 1-set 2-iterator 6-stop 7-group 
33. 1-set 2-iterator 7-group 
34. 1-set 3-rewind 
35. 1-set 3-rewind 4-bound 
36. 1-set 3-rewind 4-bound 5-undef 
37. 1-set 3-rewind 4-bound 5-undef 6-stop 
38. 1-set 3-rewind 4-bound 5-undef 6-stop 7-group 
39. 1-set 3-rewind 4-bound 5-undef 7-group 
40. 1-set 3-rewind 4-bound 6-stop 
41. 1-set 3-rewind 4-bound 6-stop 7-group 
42. 1-set 3-rewind 4-bound 7-group 
43. 1-set 3-rewind 5-undef 
44. 1-set 3-rewind 5-undef 6-stop 
45. 1-set 3-rewind 5-undef 6-stop 7-group 
46. 1-set 3-rewind 5-undef 7-group 
47. 1-set 3-rewind 6-stop 
48. 1-set 3-rewind 6-stop 7-group 
49. 1-set 3-rewind 7-group 
50. 1-set 4-bound 
51. 1-set 4-bound 5-undef 
52. 1-set 4-bound 5-undef 6-stop 
53. 1-set 4-bound 5-undef 6-stop 7-group 
54. 1-set 4-bound 5-undef 7-group 
55. 1-set 4-bound 6-stop 
56. 1-set 4-bound 6-stop 7-group 
57. 1-set 4-bound 7-group 
58. 1-set 5-undef 
59. 1-set 5-undef 6-stop 
60. 1-set 5-undef 6-stop 7-group 
61. 1-set 5-undef 7-group 
62. 1-set 6-stop 
63. 1-set 6-stop 7-group 
64. 1-set 7-group 
