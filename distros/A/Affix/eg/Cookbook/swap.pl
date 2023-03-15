use Affix;
affix './swap.so', swap => [ Pointer [Int], Pointer [Int] ] => Void;
my $a = 1;
my $b = 2;
print "[a,b] = [$a,$b]\n";
swap( $a, $b );
print "[a,b] = [$a,$b]\n";
