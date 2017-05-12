use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus::Applicative::Identity;
use lib "t";
use testlib::ApplicativeUtil qw(make_applicative_methods test_functor_basic);
use testlib::Identity qw(identical);

my $c = "Data::Focus::Applicative::Identity";

make_applicative_methods($c, sub { $_[0]->run_identity eq $_[1]->run_identity });

test_functor_basic($c, builder_called => 1);

{
    note("--- tests for Identity functor");
    is($c->pure("foobar")->run_identity, "foobar", "pure, run_identity()");

    my $ref = [];
    identical($c->pure($ref)->run_identity, $ref, "pure, run_identity() returns identical object");
}

{
    my $count = 0;
    my $result = $c->fmap_ap(sub { $count++; $_[0] * $_[1] * $_[2] }, map { $c->pure($_) } 3, 4, 5);
    is $count, 1, "mapper called once";
    is $result->run_identity, 60, "result OK";
}

done_testing;

