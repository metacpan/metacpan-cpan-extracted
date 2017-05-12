#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Bytes::Random::Secure::Tiny;

{
    my $rv = eval { Bytes::Random::Secure::Tiny->new(bits=>32) } || $@;
    like $rv, qr/Number of bits must be 64/, 'BRST->new: Insufficient bits throws.';
}
{
    my $rv = eval { Bytes::Random::Secure::Tiny->new(bits=>16384) } || $@;
    like $rv, qr/Number of bits must be 64/, 'BRST->new: Too many bits throws.';
}
{
    my $rv = eval { Bytes::Random::Secure::Tiny->new(bits=>67) } || $@;
    like $rv, qr/Number of bits must be 64/, 'BRST->new: non-multiple of 2^n throws.';
}

{
    my $o = Bytes::Random::Secure::Tiny->new(nonblocking=>1);
    is ref($o), 'Bytes::Random::Secure::Tiny', 'BRST->new: no bits supplied; default used.';
}

{
    my $rng = Bytes::Random::Secure::Tiny->new;
    my $rv = eval { $rng->_ranged_randoms(2**32+1, 1); 1 } || $@;
    like $rv, qr/exceeds irand max limit of 2\^\^32/, 
        '_ranged_randoms: range size overflow dies.';
}

done_testing;
