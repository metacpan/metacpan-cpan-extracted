use Affix;
use strict;
$|++;
affix './array_sum.so', array_sum => [ ArrayRef [Int] ], Int;
print array_sum(undef),            "\n";    # -1
print array_sum( [0] ),            "\n";    # 0
print array_sum( [ 1, 2, 3, 0 ] ), "\n";    # 6
