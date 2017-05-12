#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

use_ok('Acme::Mandolion::Utils');
ok( defined &Acme::Mandolion::Utils::sum, 'sum() is defined');

my @good_list = 1 .. 10;
is( Acme::Mandolion::Utils::sum( @good_list), 55, 'The sum is of 1 to 10 is 55');

my @weird_list = qw(1 2 3 a b c 123abc);
is(Acme::Mandolion::Utils::sum(@weird_list), 129, 'the weird sum is 128');

