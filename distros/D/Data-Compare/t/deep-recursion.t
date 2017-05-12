#!/usr/bin/perl -w

use strict;
use warnings;
# use diagnostics;

use Data::Compare;
use Test::More tests => 3;

my $warning= '';
$SIG{__WARN__} = sub { $warning= shift; };

my($data1, $data2) = ({}, {});
foreach my $i (qw(a b c d e f g h i j)) {
    foreach my $j (qw(k l m n o p q r s t)) {
        $data1->{$i}->{$j} = 'i like pie';
        $data2->{$i}->{$j} = 'i like pie';
    }
}

# check that we DTRT on very deep recursion
$a = [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[0]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]];
$b = [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[0]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]];
Compare($a, $b);
ok($warning, "warn on deep recursion");
$warning = '';

Compare([5], [5]) foreach(1..1000);
ok(!$warning, "recursion counter correctly reset");


Compare($data1, $data2);

ok(!$warning, "no warnings emitted on large flat structures");
