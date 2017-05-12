#!/usr/local/bin/perl
use strict;
use warnings;

use Test::More tests => 64;
use Array::Each;

# Testing parms combos that include count
# Note, _each not included here, other than its being automatically
#       set based on the values of the other attributes.
# Note, see test 05-AE-parms_combos for parms combos that don't
#       include count

# go: create a test string using parm combo
use constant NOWARN=>0;
sub go {
    my( $obj, $n, $warn ) = @_;
    $n ||= 1;  # num loops
    $warn = defined $warn ? $warn : 1;
    local $" = '';
    my $r = '';
    if( $warn ) {
        for(1..$n){while(my(@a)=$obj->each){$r.=">@a"}}}
    else { no warnings 'uninitialized';
        for(1..$n){while(my(@a)=$obj->each){$r.=">@a"}}}
    $r;
}

my @x = qw( a b c d e );
my @y = ( 1..9 );
my( $obj, $r );

#  1. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>__783>de454>__675',
    "combo  1. 1 2 3 4 5 6 7 8" );

#  2. 1-set 2-iterator 3-rewind 4-bound 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>_64>_75>d46>e57>_68>_79',
    "combo  2. 1 2 3 4 5 6 8" );

#  3. 1-set 2-iterator 3-rewind 4-bound 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, undef=>'_', group=>2, count=>0
    );
is( go($obj,2,NOWARN),
    '>cd340>e_561>__782>__9_3>de454>__675>__896',
    "combo  3. 1 2 3 4 5 7 8" );

#  4. 1-set 2-iterator 3-rewind 4-bound 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>_64>_75>_86>_97>d48>e59>_610>_711>_812>_913',
    "combo  4. 1 2 3 4 5 8" );

#  5. 1-set 2-iterator 3-rewind 4-bound 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>783>de454>675',
    "combo  5. 1 2 3 4 6 7 8" );

#  6. 1-set 2-iterator 3-rewind 4-bound 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>64>75>d46>e57>68>79',
    "combo  6. 1 2 3 4 6 8" );

#  7. 1-set 2-iterator 3-rewind 4-bound 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>783>94>de455>676>897',
    "combo  7. 1 2 3 4 7 8" );

#  8. 1-set 2-iterator 3-rewind 4-bound 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, bound=>0, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>64>75>86>97>d48>e59>610>711>812>913',
    "combo  8. 1 2 3 4 8" );

#  9. 1-set 2-iterator 3-rewind 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>de453',
    "combo  9. 1 2 3 5 6 7 8" );

# 10. 1-set 2-iterator 3-rewind 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>d44>e55',
    "combo 10. 1 2 3 5 6 8" );

# 11. 1-set 2-iterator 3-rewind 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>de453',
    "combo 11. 1 2 3 5 7 8" );

# 12. 1-set 2-iterator 3-rewind 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>d44>e55',
    "combo 12. 1 2 3 5 8" );

# 13. 1-set 2-iterator 3-rewind 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>de453',
    "combo 13. 1 2 3 6 7 8" );

# 14. 1-set 2-iterator 3-rewind 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>d44>e55',
    "combo 14. 1 2 3 6 8" );

# 15. 1-set 2-iterator 3-rewind 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>de453',
    "combo 15. 1 2 3 7 8" );

# 16. 1-set 2-iterator 3-rewind 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, rewind=>3, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>d44>e55',
    "combo 16. 1 2 3 8" );

# 17. 1-set 2-iterator 4-bound 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>__783>ab124>cd345>e_566>__787',
    "combo 17. 1 2 4 5 6 7 8" );

# 18. 1-set 2-iterator 4-bound 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>_64>_75>a16>b27>c38>d49>e510>_611>_712',
    "combo 18. 1 2 4 5 6 8" );

# 19. 1-set 2-iterator 4-bound 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>__783>__9_4>ab125>cd346>e_567>__788>__9_9',
    "combo 19. 1 2 4 5 7 8" );

# 20. 1-set 2-iterator 4-bound 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>_64>_75>_86>_97>a18>b29>c310>d411>e512>_613>_714>_815>_916',
    "combo 20. 1 2 4 5 8" );

# 21. 1-set 2-iterator 4-bound 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>783>ab124>cd345>e566>787',
    "combo 21. 1 2 4 6 7 8" );

# 22. 1-set 2-iterator 4-bound 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>64>75>a16>b27>c38>d49>e510>611>712',
    "combo 22. 1 2 4 6 8" );

# 23. 1-set 2-iterator 4-bound 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>783>94>ab125>cd346>e567>788>99',
    "combo 23. 1 2 4 7 8" );

# 24. 1-set 2-iterator 4-bound 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, bound=>0, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>64>75>86>97>a18>b29>c310>d411>e512>613>714>815>916',
    "combo 24. 1 2 4 8" );

# 25. 1-set 2-iterator 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>ab123>cd344>e_565',
    "combo 25. 1 2 5 6 7 8" );

# 26. 1-set 2-iterator 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>a14>b25>c36>d47>e58',
    "combo 26. 1 2 5 6 8" );

# 27. 1-set 2-iterator 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e_562>ab123>cd344>e_565',
    "combo 27. 1 2 5 7 8" );

# 28. 1-set 2-iterator 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>a14>b25>c36>d47>e58',
    "combo 28. 1 2 5 8" );

# 29. 1-set 2-iterator 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>ab123>cd344>e565',
    "combo 29. 1 2 6 7 8" );

# 30. 1-set 2-iterator 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>a14>b25>c36>d47>e58',
    "combo 30. 1 2 6 8" );

# 31. 1-set 2-iterator 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>cd341>e562>ab123>cd344>e565',
    "combo 31. 1 2 7 8" );

# 32. 1-set 2-iterator 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    iterator=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>c31>d42>e53>a14>b25>c36>d47>e58',
    "combo 32. 1 2 8" );

# 33. 1-set 3-rewind 4-bound 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>__784>de455>__676',
    "combo 33. 1 3 4 5 6 7 8" );

# 34. 1-set 3-rewind 4-bound 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>_66>_77>d48>e59>_610>_711',
    "combo 34. 1 3 4 5 6 8" );

# 35. 1-set 3-rewind 4-bound 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>__784>__9_5>de456>__677>__898',
    "combo 35. 1 3 4 5 7 8" );

# 36. 1-set 3-rewind 4-bound 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>_66>_77>_88>_99>d410>e511>_612>_713>_814>_915',
    "combo 36. 1 3 4 5 8" );

# 37. 1-set 3-rewind 4-bound 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>784>de455>676',
    "combo 37. 1 3 4 6 7 8" );

# 38. 1-set 3-rewind 4-bound 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>66>77>d48>e59>610>711',
    "combo 38. 1 3 4 6 8" );

# 39. 1-set 3-rewind 4-bound 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>784>95>de456>677>898',
    "combo 39. 1 3 4 7 8" );

# 40. 1-set 3-rewind 4-bound 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, bound=>0, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>66>77>88>99>d410>e511>612>713>814>915',
    "combo 40. 1 3 4 8" );

# 41. 1-set 3-rewind 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>de454',
    "combo 41. 1 3 5 6 7 8" );

# 42. 1-set 3-rewind 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>d46>e57',
    "combo 42. 1 3 5 6 8" );

# 43. 1-set 3-rewind 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>de454',
    "combo 43. 1 3 5 7 8" );

# 44. 1-set 3-rewind 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>d46>e57',
    "combo 44. 1 3 5 8" );

# 45. 1-set 3-rewind 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>de454',
    "combo 45. 1 3 6 7 8" );

# 46. 1-set 3-rewind 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>d46>e57',
    "combo 46. 1 3 6 8" );

# 47. 1-set 3-rewind 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>de454',
    "combo 47. 1 3 7 8" );

# 48. 1-set 3-rewind 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    rewind=>3, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>d46>e57',
    "combo 48. 1 3 8" );

# 49. 1-set 4-bound 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>__784>ab125>cd346>e_567>__788',
    "combo 49. 1 4 5 6 7 8" );

# 50. 1-set 4-bound 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>_66>_77>a18>b29>c310>d411>e512>_613>_714',
    "combo 50. 1 4 5 6 8" );

# 51. 1-set 4-bound 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>__784>__9_5>ab126>cd347>e_568>__789>__9_10',
    "combo 51. 1 4 5 7 8" );

# 52. 1-set 4-bound 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>_66>_77>_88>_99>a110>b211>c312>d413>e514>_615>_716>_817>_918',
    "combo 52. 1 4 5 8" );

# 53. 1-set 4-bound 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>784>ab125>cd346>e567>788',
    "combo 53. 1 4 6 7 8" );

# 54. 1-set 4-bound 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>66>77>a18>b29>c310>d411>e512>613>714',
    "combo 54. 1 4 6 8" );

# 55. 1-set 4-bound 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>784>95>ab126>cd347>e568>789>910',
    "combo 55. 1 4 7 8" );

# 56. 1-set 4-bound 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    bound=>0, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>66>77>88>99>a110>b211>c312>d413>e514>615>716>817>918',
    "combo 56. 1 4 8" );

# 57. 1-set 5-undef 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>ab124>cd345>e_566',
    "combo 57. 1 5 6 7 8" );

# 58. 1-set 5-undef 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>a16>b27>c38>d49>e510',
    "combo 58. 1 5 6 8" );

# 59. 1-set 5-undef 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e_563>ab124>cd345>e_566',
    "combo 59. 1 5 7 8" );

# 60. 1-set 5-undef 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    undef=>'_', count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>a16>b27>c38>d49>e510',
    "combo 60. 1 5 8" );

# 61. 1-set 6-stop 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    stop=>6, group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>ab124>cd345>e566',
    "combo 61. 1 6 7 8" );

# 62. 1-set 6-stop 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    stop=>6, count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>a16>b27>c38>d49>e510',
    "combo 62. 1 6 8" );

# 63. 1-set 7-group 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    group=>2, count=>1
    );
is( go($obj,2,NOWARN),
    '>ab121>cd342>e563>ab124>cd345>e566',
    "combo 63. 1 7 8" );

# 64. 1-set 8-count
$obj = Array::Each->new( set=>[\@x, \@y],
    count=>1
    );
is( go($obj,2,NOWARN),
    '>a11>b22>c33>d44>e55>a16>b27>c38>d49>e510',
    "combo 64. 1 8" );

__END__
