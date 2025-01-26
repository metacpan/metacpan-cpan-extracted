#!/usr/bin/perl -s
##
##
##
## Copyright (c) 1999, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

use Crypt::Primes; 
use Math::Pari qw(floor);

print "1..10\n";

my $t = 0;
for ( qw( 128 256 512 768 1024 ) ) { 
    print "generating a random $_-bit prime...\n";
    my $prime = Crypt::Primes::maurer ( Size => $_, Verbosity => 1, Generator => 1); 
    print "\n$prime->{Prime}, $prime->{Generator}\n"; $t++;
    print Math::Pari::isprime( $prime->{Prime} ) ? "ok $t\n" : "not ok $t\n";  $t++;
    print bitsize($prime->{Prime}) == $_ ? "ok $t\n" : "not ok $t\n";
}

sub bitsize {
    return floor(Math::Pari::log(shift)/Math::Pari::log(2)) + 1;
}



