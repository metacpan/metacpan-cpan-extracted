#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core), {};
{
    package Foo;
    use Assert::Refute::T::Basic;
}

my $report;

$report = try_refute {
    package Foo;
    is_deeply {bar => 2}, {foo => 1 };
};

is $report->get_count, 1, "is_deeply bad: 1 test run";
ok !$report->is_passing, "is_deeply bad: not passing";
note $report->get_tap;

$report = try_refute {
    package Foo;
    is_deeply {foo => 1}, {foo => 1 };
};

is $report->get_count, 1, "is_deeply good: 1 test run";
ok $report->is_passing, "is_deeply good: passing";

$report = try_refute {
    package Foo;
    note foo => { x => 42 };
    diag "bared";
};

like $report->get_tap(2), qr/^## foo \{ *["']?x["']? *=> *42 *\}/, "note works";
like $report->get_tap(2), qr/\n# bared/, "diag works";

$report = try_refute {
    package Foo;
    is 42, 137;
    like "foobar", "f.*b.*r";
};

is $report->get_count, 2, "is + like bad: 2 tests run";
ok !$report->is_passing, "is + like bad: not passing";
note $report->get_tap;

done_testing;
