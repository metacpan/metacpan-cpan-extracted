#!/usr/bin/perl
 use Acme::Tools;
 use Math::BigFloat try => 'GMP';  # pure perl, no warnings if GMP not installed
 my $start=Math::BigFloat->new(1);
 my $gr1 = resolve(sub{my$x=shift; $x-1-1/$x;},0,1);     # 1/2 + sqrt(5)/2
 my $gr2 = resolve(sub{my$x=shift; $x-1-1/$x;},0,$start);# 1/2 + sqrt(5)/2
 Math::BigFloat->div_scale(50);
 my $gr3 = resolve(sub{my$x=shift; $x-1-1/$x;},0,$start);# 1/2 + sqrt(5)/2
 print "Golden ratio 1: $gr1\n";
 print "Golden ratio 2: $gr2\n";
 print "Golden ratio 3: $gr3\n";
