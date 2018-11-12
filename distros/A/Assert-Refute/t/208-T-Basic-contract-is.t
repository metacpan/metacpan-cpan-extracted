#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::Contract qw(contract);

my $inner = contract {
    refute shift, "t1";
    refute shift, "t2";
};

my $outer = contract {
    my $exp = shift;
    contract_is $inner->apply(@_), $exp, "Contract as expected";
};

my $run1 = $outer->apply( "t2d", 0, 0 );
is $run1->get_sign, "t1d", "Happy case";
note $run1->get_tap;

my $run2 = $outer->apply( "tNNd", 42, 137 );
is $run2->get_sign, "t1d", "Inner failed";
note $run2->get_tap;

my $run3 = $outer->apply( "tNNd", 0, 0 );
is $run3->get_sign, "tNd", "Outer failed";
note $run3->get_tap;
like $run3->get_tap
    , qr([Ss]ignature.*Got.*t2d.*Expected.*tNNd.*log.*# ok 1.*# ok 2.*# 1..2)s
    , "Reason explained in tap";

done_testing;
