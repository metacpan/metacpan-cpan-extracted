# make test
# perl Makefile.PL; make; perl -Iblib/lib t/16_fractional.t

BEGIN{require 't/common.pl'}
use Test::More tests => 1;

ok(1); #NOT FINISHED
exit;

#my $n=2135.135135135135135135;
#my $n=0.725234234234*100000000;
#my $n=12/7;
#my $n=big(13)/(2*2*2*2*3*3*7);
#my $n=0.15/(2*2*2*3*3*7);
for(1..10){
  my($ti,$ni)=map random(1,10),1..2; print "----$ti/$ni    ";
  my($to,$no)=fractional($n=$ti/$ni);
  print "$ti/$ni -> $n -> ".join(" / ",$to||'?', $no||'?')."\n";
  print $to/$no,"\n" if $no;
}