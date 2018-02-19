
sub perm0 {
  my @a=@_;
  my $n=@a;
  my @c=map 0, 1..$n;
  print join(" ",@a)."\n";
  my $i=0;
  while($i<$n){
      if($c[$i]<$i){
	  if($i%2==0){  @a[0,$i]=@a[$i,0]           }
	  else       {  @a[$c[$i],$i]=@a[$i,$c[$i]] }
	  $c[$i]++;
	  $i=0;
	  print join(" ",@a)."\n";
      }
      else{
	  $c[$i]=0;
	  $i++;
      }
  }
}

sub perm_slow { #same golfed
    my(@a,@c,$i,$p)=@_;
    my $o=sub{print join("",map"$_ ",@a)."\n"}; &$o;
    $c[$i]>=$i and $c[$i++]="0e0" or $p=$c[$i]++*($i%2),@a[$p,$i]=@a[$i,$p],$i=0,&$o while $i<@a;
}
sub perm { #same golfed and faster
    my(@a,@c,$i,$p)=@_;
    print join(" ",@a)."\n";
    $c[$i]>=$i and $c[$i++]="0e0" or $p=$c[$i]++*($i%2),@a[$p,$i]=@a[$i,$p],$i=0,print(join(" ",@a)."\n") while $i<@a;
}

my $n=shift||4;
my @a=1..$n;
perm(@a);

__END__
https://en.wikipedia.org/wiki/Heap%27s_algorithm
time perl perm2.pl 8|md5sum                 #a3fc159cae1cdda4e3c8db1021a2ec81
time perl perm2.pl 8|sort|md5sum            #b34c300f7ec5e403f6f7aac1997e3f9d
time perl perm.pl 8|md5sum                  #samme
