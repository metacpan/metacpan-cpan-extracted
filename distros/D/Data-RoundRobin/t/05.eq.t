#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

my @arr = qw(a b c);
plan tests => (1 + 3*scalar(@arr));
use_ok('Data::RoundRobin');

my $rr = Data::RoundRobin->new(@arr);
for(my $i = 0; $i < 3 * @arr ; $i++) {
    ok($rr eq $arr[$i % 3])
}
