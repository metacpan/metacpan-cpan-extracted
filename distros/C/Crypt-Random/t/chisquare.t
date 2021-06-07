#!/usr/bin/perl -sw -I../lib/ -Ilib/
##
##
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test;
use Crypt::Random::Generator;
use Statistics::ChiSquare;
BEGIN { plan tests => 1 };

tests( new Crypt::Random::Generator Strength => 0, Uniform => 1 );

sub tests { 

    my $gen = shift;
    my $x;
    my $count = 1000;
    my $n = 16;
    my @q = (0, 0, 0, 0);
    my $q_size = (2**$n)/4;
    for (0 .. $count) { 
        my $x = $gen->integer (Size => $n);
        if ($x <= $q_size) { 
            $q[0]++
        } elsif ($x <= $q_size*2) { 
            $q[1]++
        } elsif ($x <= $q_size*3) { 
            $q[2]++
        } else { 
            $q[3]++;
        }
    }
    print STDERR "\nQuartile distribution of $count $n-bit random numbers was @q\n";
    my $chi = chisquare(@q);
    print STDERR "$chi\n";
    ok($chi =~ m/\>[1-9]/);
}
