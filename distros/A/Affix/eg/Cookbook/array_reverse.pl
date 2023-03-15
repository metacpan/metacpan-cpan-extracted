use Affix;
use strict;
$|++;
affix './array_reverse.so', array_reverse => [ ArrayRef [Int], Int ], Int;
affix './array_reverse.so', array_reverse10 => [ ArrayRef [ Int, 10 ] ], Int;
#
my @a = ( 1 .. 10 );
array_reverse10( \@a );
print "$_ " for @a;
print "\n";
#
@a = ( 1 .. 20 );
array_reverse( \@a, 20 );
print "$_ " for @a;
print "\n";
#
my $a = [ 1 .. 20 ];
array_reverse( $a, 20 );
print "$_ " for @$a;
print "\n";
