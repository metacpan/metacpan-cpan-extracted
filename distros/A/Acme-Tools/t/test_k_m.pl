#!/usr/bin/perl
use Acme::Tools;
my $cool=resolve(sub{(bfdimensions(1e6,$_[0]))[0]/8-1e6},0,0.02);
my(@tm1,@tm2);
my @cap=map 10**$_,1..12;
my @er=qw/0.99 0.5 0.1 0.01 0.001 0.0001 0.00001 0.000001 0.0000001 0.00000001 0.000000001/; splice@er,3,0,$cool;
for my $cap (@cap){
  for my $er (@er){
    my($m1,$k1)=Acme::Tools::bfdimensions_old($cap,$er);
    my($m2,$k2)=Acme::Tools::bfdimensions($cap,$er);
    push @tm1,[$cap,"Error-rate\n$er",sprintf("%.4g",0.5+$m1/8)];
    push @tm2,[$cap,"Error-rate\n$er",sprintf("%.4g",0.5+$m2/8)];
  }
}
print "Storage, method 1 (bytes):\n".tablestring([pivot(\@tm1,"Capacity")]),"\n";
print "Storage, method 2 (bytes):\n".tablestring([pivot(\@tm2,"Capacity")]),"\n";

for(@er){
  printf "Error rate: %18s   Hash functions(1): %2d   Hash functions(2): %2d\n",
    $_,
    (Acme::Tools::bfdimensions_old(1,$_))[1],
    (Acme::Tools::bfdimensions(1,$_))[1],
}

