#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Acme::ELLEDNERA::Utils "sum";

ok( defined &sum, "Acme::ELLEDNERA::Utils::sum export ok" );
is( sum(1, 2, 3), 6, "1+2+3 = 6");
is( sum(5, 5, 12, 9), 31, "5+5+12+9 = 31");
is( sum(1.2, 3.14159), 4.34159, "1.2+3.14159 = 4.34159");
is( sum( qw(t1 t2) ), undef, "Non-numeric shouldn't work :)");
is( sum( qw(t1 10 t2 5 6) ), 21, "Mixture only return sum of numerics (21)");

done_testing();

# besiyata d'shmaya


