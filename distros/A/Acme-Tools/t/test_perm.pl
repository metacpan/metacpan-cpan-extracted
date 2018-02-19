
my $n=shift()||4;
my@a=(1..$n);
while(1){
    print join(" ", @a)."\n";
    my $k=$n-2; 1 while $a[$k]>$a[$k+1] and $k--; last if $k<0;
    my $l=$n-1; 1 while $a[$k]>$a[$l]   and $l-->$k;
    @a[$k,$l]=@a[$l,$k];
    @a[$k+1..$#a]=reverse@a[$k+1..$#a] if $k<$n-2;
}


__END__
#https://en.wikipedia.org/wiki/Permutation#Generation_in_lexicographic_order
# prints e-1 !                       2.718281 - 1
my@a=(1..$n); #bryr seg ikke om elementene saalenge de starter sortert, er unike og sammenlignbare med <
my($i,$s)=(0,0);
while(1){
    $i++;
    print join(" ", @a)."\n";
    my $k=$n-2; 1 while $a[$k]>=$a[$k+1] and $k--; last if $k<0;
    my $l=$n-1; 1 while $a[$k]>=$a[$l]   and $l-->$k;
    @a[$k,$l]=@a[$l,$k];
    next if $k == $n-2 and ++$s; #next not needed, but speeds up
    $s+=$#a-$k;
    @a[$k+1..$#a] = reverse @a[$k+1..$#a] ;
}
print STDERR "avg=".($s/$i)."\n";
