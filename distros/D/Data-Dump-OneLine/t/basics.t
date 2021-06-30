#!perl

use strict;
use warnings;

use Test::More 0.98;
use Data::Dump::OneLine;

is(dmp(1), 1);
is(dmp("a\nb"), q["a\\nb"]);

my $a = [1, 2]; $a->[2] = $a;
is(dmp($a), q[do{my$var=[1,2,'$var'];$var->[2]=$var;$var}], "arrayref 2");

done_testing;
