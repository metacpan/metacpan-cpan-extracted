#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken refaddr );

use Assert::Refute::Report;

my $parent = Assert::Refute::Report->new;

$parent->subcontract("inner test" => sub {
    my $inner = shift;

    $inner->ok(1);
});

my $details = $parent->get_result_details(1);

my $child = $details->{subcontract};

isa_ok $child, "Assert::Refute::Report";

is refaddr $child->get_parent, refaddr $parent, "subcontract retains parent";

weaken $parent;

is $parent, undef, "report is not leaky";
is $child->get_parent, undef, "parent updated";

done_testing;
