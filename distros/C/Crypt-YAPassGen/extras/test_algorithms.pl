#!/usr/bin/perl

use strict;
use Crypt::YAPassGen;
$|=1;

=pod
This program tests various algorithms for security by recording how long
it takes for the same password to be generated twice.
You may personalize your object to test different settings.
I also suggest to test new frequency files as they may have some weakness.
=cut

my $pm = Crypt::YAPassGen->new();

my %avr;

printf "%8s\t%5s\t%8s\t%s\n", qw(Alg # Try Password);

for my $alg (keys %{ Crypt::YAPassGen->ALGORITHMS }) {
    $pm->algorithm($alg);
    my $tries = 10;
    for my $i (1..$tries) {
        printf "%8s\t%2d/%2d\t", $alg, $i, $tries;
        my ($p, %c, $j);
        while (++$j) {
            $p = $pm->generate();
            printf "%8d\t%s\n",$j, $p and last if $c{$p}++;
        }
        $avr{$alg} += $j;
    }
    $avr{$alg} /= 10;
}

for (keys %avr) {
    print "Average for $_ = $avr{$_}\n";
}



