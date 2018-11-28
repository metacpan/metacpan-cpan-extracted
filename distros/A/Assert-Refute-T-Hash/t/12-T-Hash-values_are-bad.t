#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Report;
use Assert::Refute::T::Errors;
use Assert::Refute::T::Hash;

warns_like {
    my $bad_contract = sub {
        # Value spec is wrong, so this dies
        values_are { foo => {} }, { foo => {} }, "Fails";
    };

    my $report = Assert::Refute::Report->new;
    dies_like {
        $report->values_are( { foo => {} }, { foo => {} } );
    } qr/Unexpected.*foo.*HASH/, "Test warns about bad spec";

    note $report->get_tap;
} '', "No warnings overall";

done_testing;
