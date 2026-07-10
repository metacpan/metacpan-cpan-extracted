#!/usr/bin/perl

#use lib '../lib';

use Test::More;
use Crypto::Utils::OpenSSL;

my $Nn  = 16;
my $rnd = random_bn($Nn);
print BN_bn2hex($rnd), "\n";
ok( defined $rnd && BN_bn2hex($rnd), 'random_bn' );
cmp_ok( length( BN_bn2hex($rnd) ), '<=', $Nn * 2, 'random_bn length <= Nn*2' );

done_testing;

1;
