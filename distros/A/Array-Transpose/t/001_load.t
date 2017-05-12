# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 33;
BEGIN { use_ok( 'Array::Transpose' ); }
my @in=(
        [qw{1 2 3 4 5}],
        [qw{a b c d e}],
       );
my $out=transpose(\@in);
is(scalar(@$out), 5, 'Scalar Context');
is(scalar(@{$out->[0]}), 2, 'Scalar Context');
isa_ok($out, "ARRAY");
isa_ok($out->[0], "ARRAY");
is($out->[0]->[0], "1", "data");
is($out->[1]->[0], "2", "data");
is($out->[2]->[0], "3", "data");
is($out->[3]->[0], "4", "data");
is($out->[4]->[0], "5", "data");
is($out->[0]->[1], "a", "data");
is($out->[1]->[1], "b", "data");
is($out->[2]->[1], "c", "data");
is($out->[3]->[1], "d", "data");
is($out->[4]->[1], "e", "data");

my @out=transpose(\@in);
is(scalar(@out), 5, 'Array Context');
is(scalar(@{$out[0]}), 2, 'Array Context');
isa_ok($out[0], "ARRAY");
is($out[0]->[0], "1", "data");
is($out[1]->[0], "2", "data");
is($out[2]->[0], "3", "data");
is($out[3]->[0], "4", "data");
is($out[4]->[0], "5", "data");
is($out[0]->[1], "a", "data");
is($out[1]->[1], "b", "data");
is($out[2]->[1], "c", "data");
is($out[3]->[1], "d", "data");
is($out[4]->[1], "e", "data");


my $size=500000;
my $in=[[1 .. $size]];
$out=transpose $in;

isa_ok($out, "ARRAY");
is(scalar(@$out), $size, "Large Array 1");
is($out->[0]->[0], "1", "First First Value 1");
is($out->[$size-1]->[0], "$size", "Last Last Value 1");

my @list=transpose [map {[$_]} ("a" .. "z")];
is(scalar(@list), "1", "anonymous array reference");
