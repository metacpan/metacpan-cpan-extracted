# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 14;
use Array::Transpose qw{};
my @in=(
        [qw{1 2 3 4 5}],
        [qw{a b c d e}],
       );
my $out=Array::Transpose::transpose(\@in);
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
