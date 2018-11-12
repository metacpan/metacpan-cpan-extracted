#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;
use Carp;

use Assert::Refute qw(:core), {};
use Assert::Refute::T::Errors;

my $report = try_refute {
    warns_like {
    } [], "No warnings";

    warns_like {
        warn "Foo";
        carp "Bar";
    } [qr/^Foo/, "^Bar"], "Exp warnings";

    warns_like {
        warn "Bar";
    } qr/^Foo/, "Unexpected warning";

    warns_like {
        # no warnings
    } qr/^Foo/, "Missing expected warning";

    warns_like {
        warn "Foo";
    } [], "Extra warning";

    warns_like {
        warn "Foo";
        warn "Bar";
    } qr/^Foo/, "Extra second warning";
};

contract_is $report, "t2NNNNd", "Contract as expected";
note "REPORT\n".$report->get_tap."/REPORT";

done_testing;
