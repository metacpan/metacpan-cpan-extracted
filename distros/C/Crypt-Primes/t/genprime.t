#!/usr/bin/perl -s
##
##
##
## Copyright (c) 1999, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

use Crypt::Primes qw(maurer); 
use Math::Pari qw(floor);

print "1..10\n";

print "$Crypt::Primes::VERSION\n";

my $t = 0;
for ( qw( 128 256 384 512 1024 ) ) { 
    print "generating a random $_-bit prime...\n";
    my $prime = maurer ( Size => $_, Verbosity => 1); print "\n$prime\n"; $t++;
    print Math::Pari::isprime( $prime ) ? "ok $t\n" : "not ok $t\n";  $t++;
    print bitsize($prime) == $_ ? "ok $t\n" : "not ok $t\n";
}

sub bitsize {
    return floor(Math::Pari::log(shift)/Math::Pari::log(2)) + 1;
}



