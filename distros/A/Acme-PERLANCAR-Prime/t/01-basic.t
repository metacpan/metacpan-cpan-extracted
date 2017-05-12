#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Acme::PERLANCAR::Prime qw(primes);

is_deeply([primes(10)], [2,3,5,7]);

done_testing;
