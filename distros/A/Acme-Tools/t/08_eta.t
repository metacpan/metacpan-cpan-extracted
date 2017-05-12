#perl Makefile.PL;make;perl -Iblib/lib t/08_eta.t
BEGIN{require 't/common.pl'}
use Test::More tests => 6;
eta(1,100);
#warn serialize(\%Acme::Tools::Eta,'Eta','',1);
my $k=(keys%Acme::Tools::Eta)[0];
ok( @{$Acme::Tools::Eta{$k}}==1, 'ok aref');

ok(!defined eta("x",6,10,70)                ,'!def');
ok(         eta("x",8,10,80) == 90          ,'ok 90');
ok(         eta("x",8,10,80) == 90          ,'ok 90');
ok(         @{$Acme::Tools::Eta{'x'}} == 2  ,'ok len' );
#my $s=time_fp;
my @err;
for(1..2000){
  #$t=1e6+$_/100; #time_fp
  my $e=eta("id",$_,2000,1e6+$_/100);
  push @err,$_ if defined $e and abs(1-$e/1000020)>1e-5;
  #printf "%4d   %-20s   %-20s\n", $_, $t, $e if $_%100==0;
}
ok(!@err, 'no misses');
print "Err: ".join(",",@err)."\n" if @err;
#printf"%.5f\n",time_fp()-$s;