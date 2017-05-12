#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw(no_plan);

my @arr = qw(a b c);

use_ok('Data::RoundRobin');

my $rr = Data::RoundRobin->new(@arr);
for(my $i = 0; $i < 3 * @arr ; $i++) {
    cmp_ok(0+$rr, '==', 0, "Numeric Equal");
}

my $r1 = Data::RoundRobin->new(@arr);
my $r2 = Data::RoundRobin->new(@arr);
for(my $i = 0; $i < 3 * @arr ; $i++) {
    is($r1, $r2, "Synchronized round robin data");
    cmp_ok($r1, "eq", $r2, "Synchronized round robin data");
}
