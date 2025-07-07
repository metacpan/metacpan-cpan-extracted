#!/usr/bin/perl

#use lib '../lib';

use Test::More;
use Crypt::OpenSSL::BaseFunc;

my $Nn = 16;
my $rnd = random_bn($Nn);
print $rnd->to_hex, "\n";
is(length($rnd->to_hex), $Nn*2, 'random_bn');

done_testing;

1;
