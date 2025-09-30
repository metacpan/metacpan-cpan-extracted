#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Carp;

BEGIN { delete @ENV{qw{ NDEBUG PERL_NDEBUG }} };
use Assert::Refute qw(assert_refute);

our %cb; # for local
Assert::Refute->configure({
    on_pass => sub { $cb{pass}++ },
    on_fail => sub { $cb{fail}++ },
});

my $all_good = q{ IF YOU SEE THIS, THE TESTS FAILED };

subtest "Failing runtime assertion" => sub {
    local %cb;

    my $report = assert_refute {
        package T;
        use Assert::Refute::T::Basic;

        is 42, 137, $all_good;
    };

    is_deeply \%cb, { fail => 1 }, "callback: 1 fail, no pass";
    is $report->get_sign, "tNd", "Signature ok";
};

subtest "Passing runtime assertion" => sub {
    local %cb;

    my $report = assert_refute {
        package T;
        use Assert::Refute::T::Basic;

        is 42, 42, $all_good;
    };

    is_deeply \%cb, { pass => 1 }, "callback: 1 pass, no fail";
    is $report->get_sign, "t1d", "Signature ok";
};

subtest "Dying runtime assertion" => sub {
    local %cb;


    my $report = eval {
        assert_refute {
            package T;
            use Assert::Refute::T::Basic;

            is 42, 42, $all_good;
            die "You shall not pass";
        };
    };
    my $err = $@;

    is $report, undef, "dies = no return";
    like $err, qr/^You shall not pa/, "Error retained";

    is_deeply \%cb, { }, "callback: no pass, no fail";
} if 0;

done_testing;
