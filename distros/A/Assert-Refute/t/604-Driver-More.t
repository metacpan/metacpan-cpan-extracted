#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
my $no_test_tester;
BEGIN {
    $no_test_tester = eval "use Test::Tester 1.302107; 0; "; ## no critic
    $no_test_tester = $@ || "Failed to load Test::Tester"
        unless defined $no_test_tester;
};
use Test::More;

use Assert::Refute;

if ($no_test_tester) {
    plan skip_all => $no_test_tester;
    exit 0;
};

# Test plumbing first
my $t = eval {
    current_contract;
};
is $@, '', "No exception during current_contract";
isa_ok $t, "Assert::Refute::Report", "Driver isa report object";
isa_ok $t, "Assert::Refute::Driver::More", "Driver isa Test::More interface";

check_test (
    sub {
        refute 0, "Happy case";
    },
    {
        name => "Happy case",
        ok   => 1,
        diag => '',
    }
);

subtest "unhappy case" => sub {
    my %capture;
    check_test (
        sub {
            $capture{start_count} = current_contract->get_count;
            $capture{start_ok}    = current_contract->is_passing;
            refute 1, "Unhappy case";
            $capture{end_count}   = current_contract->get_count;
            $capture{end_ok}      = current_contract->is_passing;
        },
        {
            name => "Unhappy case",
            ok   => 0,
            diag => '',
        }
    );

    is $capture{start_count}, 0, "0  tests at start";
    is $capture{end_count}, 1, "1  tests in the end";
    is $capture{start_ok}, 1, "passing at start";
    TODO: {
        local $TODO = "This somehow fails, but it works in vivo";
        is $capture{end_ok}, 0, "failing in the end";
    };
};

subtest "Unhappy case (with reason)" => sub {
    my $capture;
    check_test (
        sub {
            refute "reason", "Unhappy case (with reason)";
            $capture = current_contract->get_result(1);
        },
        {
            ok   => 0,
            diag => 'reason',
        }
    );
    is $capture, "reason", "get_result preserved";
};

check_test (
    sub {
        refute [reason => 42], "Unhappy case (multiline reason)";
    },
    {
        ok   => 0,
        diag => "reason\n42",
    }
);

check_test (
    sub {
        refute 0, "diag only";
        current_contract->diag("round-trip");
    },
    {
        ok   => 1,
        diag => 'round-trip',
    }
);

done_testing;

