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
}->apply;

contract_is $c, "t2Nd", "Contract as expected";
note $c->as_tap;

done_testing;
