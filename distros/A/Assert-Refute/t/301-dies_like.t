#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core), {};
use Assert::Refute::T::Errors qw(dies_like);

my $report = try_refute {
    dies_like {
        +1;
    } '', "Lives ok";
    dies_like {
        die "Foobared";
    } qr/^Foobared at /, "Dies ok";
    dies_like {
        die "Foobared";
    } '', "Lives not ok";
    dies_like {
        +1;
    } '^Foobared', "Dies not ok";
    dies_like {
        die "Barfooed";
    } '^Foobared', "Dies with wrong mess";
};

contract_is $report, "t2NNNd", "Contract as expected";

done_testing;
