#!perl

use strict;
use warnings;
use Test::More;
use Carp;

use Assert::Refute qw(:core);
use Assert::Refute::T::Errors;

my $c = contract {
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
}->apply;

contract_is $c, "t2NNNNd", "Contract as expected";
note "REPORT\n".$c->get_tap."/REPORT";

done_testing;
