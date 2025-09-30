#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Report;

my $rep = Assert::Refute::Report->new;

my $result = eval {
    $rep->subcontract( "this dies" => sub {
        die "Foo totally bared";
    } );
    1;
};
my $err = $@;

is $result, undef, "exception rethrown";
like $err, qr/Foo totally bared/, "exception text retained";
is $rep->get_sign, "tNr", "failed test recorded in report";

done_testing;
