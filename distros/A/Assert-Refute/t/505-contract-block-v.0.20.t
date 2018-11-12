#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;
use Assert::Refute::T::Errors;

use Assert::Refute qw(contract);

my $c1;
warns_like {
    $c1 = contract { die "Noop" };
} [qr/DEPRECATED.*Contract::contract/], "Deprecated warning sent";

isa_ok $c1, "Assert::Refute::Contract", "A contract returned";
is $c1->apply()->get_sign, "tE", "Contract is interrupted - as expected";

done_testing;
