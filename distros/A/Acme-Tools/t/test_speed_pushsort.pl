#!/usr/bin/perl
use lib 'blib/lib';
use Acme::Tools;
print "Version $Acme::Tools::VERSION\n";
for(qw/1000 10000 100000 1000000 2000000 3000000 4000000 5000000/){
  print "----------$_\n";
  my $t=time_fp();
  my @arr=sort{$a<=>$b}map rand()*100,1..$_;
  printf"%.6s init\n",time_fp()-$t;
  my @a=map rand()*100,1..10;
  $t=time_fp();
  my @f=sort{$a<=>$b}(@arr,@a);
  printf"%.6s sort\n",time_fp()-$t;
  pushsort@arr,@a;
  printf"%.6s pushsort\n",time_fp()-$t;
  print "ok\n" if join(",",@arr) eq join(",",@f);
}
