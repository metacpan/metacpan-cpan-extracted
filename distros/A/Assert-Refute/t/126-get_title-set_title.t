#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Report;

subtest "get_title, set_title" => sub {

my $rep = Assert::Refute::Report->new;
    is +$rep->set_title( "Test something" ), $rep, "set_title returns self";
    is +$rep->get_title, "Test something", "get_title round trip";
    $rep->done_testing;

    # throws_ok by hand
    my $do = eval {
        $rep->set_title("Something else");
        1;
    };

    like $@, qr/done_testing/, "set_title value is locked";
    is $do, undef, "set_title dies";

    is +$rep->get_title, "Test something", "get_title persists";
};

subtest "plan title" => sub {
    my $rep = Assert::Refute::Report->new;
    $rep->plan( title => "some test" );
    is +$rep->get_title, "some test", "Title via plan works";
};

done_testing;
