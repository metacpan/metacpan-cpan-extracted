#!/usr/bin/env perl

use strict;
use warnings FATAL => qw(recursion);
use Test::More;

use Assert::Refute::T::Basic qw(deep_diff);

my $leaf1 = [];
my $leaf2 = [];

is deep_diff( [$leaf1, $leaf1], [$leaf2, $leaf2] ), '', "same struct (DAG)";
is deep_diff( [$leaf1, $leaf2], [$leaf2, $leaf1] ), '', "same struct (tree)";

like deep_diff( [$leaf1, $leaf2], [$leaf1, $leaf1] ), qr#.*!=&.*#
    , "Tree vs DAG (vice versa isn't caught yet)";

like deep_diff( { foo=>$leaf1, bar=>$leaf2 }, { foo=>$leaf1, bar =>$leaf1 } )
    , qr/.*\Q[]!=&{bar}\E.*/
    , "Tree vs DAG (hash version)";

is deep_diff( { foo=>$leaf1, bar=>$leaf1 }, { foo=>$leaf2, bar=>$leaf2 } )
    , ''
    , "same struct in %hash";

my $deep5 = [];
push @$deep5, [[[[ $deep5 ]]]];

my $deep7 = [];
push @$deep7, [[[[[[ $deep7 ]]]]]];

note deep_diff( $deep5, $deep7 );
is deep_diff( $deep5, $deep5 ), '', "compare self => ok (doesn't hang)";

my $x = bless { foo=>42 }, 'Bar';
my $y = bless { foo=>42 }, 'Bar';
isnt( $x, $y, "Not the same");
is deep_diff( $x, $y ), '', "But structure *is* same";

is deep_diff( $x, bless { foo => 137 }, 'Bar' )
    , 'Bar{"foo":42!=137}', "Deep diff in blessed var";

done_testing;
