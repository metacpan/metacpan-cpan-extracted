package AI::NeuralNet::SOM::Utils;

sub vector_distance { 
    my ($V, $W) = (shift,shift);
#                       __________________
#                      / n-1          2
#        Distance  =  /   E  ( V  -  W )
#                   \/    0     i     i
#
#warn "bef dist ".Dumper ($V, $W);
    my $d2 = 0;
    map { $d2 += $_ }
        map { $_ * $_ }
	map { $V->[$_] - $W->[$_] } 
        (0 .. $#$W);
#warn "d2 $d2";
    return sqrt($d2);
}



1;
