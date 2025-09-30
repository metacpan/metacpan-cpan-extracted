#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 3;
use Scalar::Util qw(refaddr);

use Assert::Refute;

subtest "passing refutation" => sub {
    my $capture;
    my $rep = Assert::Refute::Report->new;
    my $ret_val = $rep->do_run( sub {
        $capture = current_contract;
        refute 0, "IF YOU SEE THIS MESSAGE, TESTS FAILED";
    } );

    is refaddr $capture, refaddr $rep, "current_contract() was set properly";
    is refaddr $ret_val, refaddr $rep, "report object returned by do_run";
    is $rep->get_sign, "t1d", "signature as expected";
};

subtest "failing refutation" => sub {
    my $rep = Assert::Refute::Report->new;

    $rep->do_run( sub {
        refute 1, "IF YOU SEE THIS MESSAGE, TESTS FAILED";
    } );

    is $rep->get_sign, "tNd", "signature as expected";
};

subtest "exception in contract" => sub {
    my $rep;
    eval {
        $rep = Assert::Refute::Report->new;
        $rep->do_run( sub {
            die "Foobared"
        } );
    };

    like $@, qr{Foobared at .* line \d+\.?\n}s, "exception propagated";

    is $rep->get_sign, "tr", "Interrupted execution = report unclosed";
};

