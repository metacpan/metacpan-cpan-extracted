#!/usr/bin/env perl

#:TAGS:

use 5.022;

use strict;  use warnings;  use autodie qw/:all/;
use experimental qw(signatures);

use Data::Dump;
################################################################################
# Both these techniques came from
# http://graphics.stanford.edu/~seander/bithacks.html

use Inline C => <<'EOC';
long nearest_higher_power_of_2a(long n) {
    if (n == 0)
      return 1;
    n -= 1;
    n |= n >>  1;
    n |= n >>  2;
    n |= n >>  4;
    n |= n >>  8;
    n |= n >> 16;
    n |= n >> 32;

    return n + 1;
}

int count_set_bits(long n) {
    int count;

    for ( count = 0; n; count++ )
        n &= n - 1;
    return count;
}
EOC

*csb_c = *count_set_bits;

sub csb_perl_loop($n) {
    my $count = 0;
    while ($n) {
        $count++ if $n & 1;
        $n >>= 1;
    }
    return $count;
}

sub csb_perl_c($n) {
    my $count = 0;
    for ( ; $n; $count++ ) {
        $n &= $n - 1;
    }
    return $count;
}

sub csb_perl_str($n) {
    my $str = sprintf "%b", $n;
    return $str =~ tr/1//d;
}

sub csb_perl_int($n) {
    my $count = 0;

    while ($n) {
        $count++ if $n & 1;
        $n >>= 1;
    }
    return $count;
}

dd csb_perl_str(10);

use Benchmark 'cmpthese';

my %jobs = (
    csb_c => sub {
        csb_c(12345);
    },
    csb_perl_c => sub {
        csb_perl_c(12345);
    },
    csb_perl_int => sub {
        csb_perl_int(12345);
    },
    csb_perl_loop => sub {
        csb_perl_loop(12345);
    },
    csb_perl_str => sub {
        csb_perl_str(12345);
    },
);

cmpthese -5, \%jobs;

#                     Rate csb_perl_loop csb_perl_int csb_perl_c csb_perl_str csb_c
# csb_perl_loop   697967/s            --          -2%       -51%         -64%  -93%
# csb_perl_int    708633/s            2%           --       -50%         -64%  -93%
# csb_perl_c     1425414/s          104%         101%         --         -27%  -86%
# csb_perl_str   1949811/s          179%         175%        37%           --  -81%
# csb_c         10269470/s         1371%        1349%       620%         427%    --
