#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::Contract qw(contract);
use Assert::Refute::T::Errors;
use Assert::Refute::T::Hash;

warns_like {

    my $c = contract {
        values_are { foo => {} }, { foo => {} }, "Fails";
    };

    my $rep;
    warns_like {
        $rep = $c->apply;
    } qr/Unexpected.*foo.*HASH/, "Test warns about bad spec";

    contract_is $rep, "tNd", "Failed but lived";

    note "REPORT\n".$rep->get_tap."/REPORT";
} '', "No warnings overall";

done_testing;
