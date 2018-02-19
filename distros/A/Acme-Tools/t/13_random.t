# make test
# perl Makefile.PL; make; perl -Iblib/lib t/13_random.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 18;

#--random, mix
for(                                 #|hmm|#
  [ sub{random([1..5])},         2000, 1.0, 1.5, 5],
  [ sub{random(["head","tail"])},1000, 1.0, 1.5, 2],
  [ sub{random(1,6)},            1000, 1.0, 1.9, 6],
  [ sub{random(2)},              1000, 1.0, 1.4, 3],
  [ sub{join(",",mix(1..4))},    1000, 1.0, 6.0, 4*3*2*1],
  [ sub{random({head=>0.48,tail=>0.48,edge=>0.04})}, 2000, 12-4,12+8, 3],
  [ sub{random({qw/1 1 2 1 3 1 4 1 5 1 6 2/})},      2000, 1.6,2.7, 6],
)
{
  my($sub,$times,$lim_from,$lim_to,$vals)=@$_;
  my %c;$c{&$sub()}++ for 1..$times;
  my @v=sort{$c{$a}<=>$c{$b}}keys%c;
 #print serialize(\%c,'c','',2),serialize(\@v,'v','',2);
  my $factor=$c{$v[-1]}/$c{$v[0]};
  ok( between($factor,$lim_from,$lim_to), " btw $lim_from $lim_to f=$factor, count=".keys(%c));
  ok($vals==keys%c);
}
ok(10==random([1..4],10),   'random arrayref -> array');
ok(10==random({1,1,2,3},10),'random hashref  -> array');

#--random_gauss
#my $srg=time_fp;
#my @IQ=map random_gauss(100,15), 1..10000;
my @IQ=random_gauss(100,15,5000);
#print STDERR "\n";
#print STDERR "time     =".(time_fp()-$srg)."\n";
#print STDERR "avg    IQ=".avg(@IQ)."\n";
#print STDERR "stddev IQ=".stddev(@IQ)."\n";
my $perc1sd  =100*(grep{$_>100-15   && $_<100+15  }@IQ)/@IQ;
my $percmensa=100*(grep{$_>100+15*2               }@IQ)/@IQ;
#print "percent within one stddev: $perc1sd\n"; # 2 * 34.1 % = 68.2 %
#print "percent above two stddevs: $percmensa\n"; # 2.2 %
#my $num=1e6;
#my @b; $b[$_/2]++ for random_gauss(100,15, $num);
#$b[$_] && print STDERR sprintf "%3d - %3d %6d %s\n",$_*2,$_*2+1,$b[$_],'=' x ($b[$_]*1000/$num) for 1..200/2;
ok( between($perc1sd,  68.2 - 4.0,  68.2 + 4.0) ); #hm, margin too small?
ok( between($percmensa, 2.2 - 0.9,   2.2 + 0.9) ); #hm, margin too small?
