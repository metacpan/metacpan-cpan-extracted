#!/usr/bin/perl

use 5.006;

use strict;
use warnings;
no  warnings 'syntax';

BEGIN {
    our $r = eval "use Test::NoWarnings; 1" || 0;
}

use Test::More tests => 1002 + $::r;

BEGIN {
    use_ok ('Acme::MathProfessor::RandomPrime') or
        BAIL_OUT ("Loading of 'Acme::MathProfessor::RandomPrime' failed");
}

ok defined $Acme::MathProfessor::RandomPrime::VERSION, "VERSION is set";


foreach (1 .. 1000) {
    my $random_prime = random_prime ();
    ok $random_prime == 17 || $random_prime == 23, "Good random prime";
}
