#!perl

use strict;
use warnings;
use Test::More tests => 2;

use Assert::Refute qw(:core);

# emulate use Foo;
BEGIN {
    package Foo;
    use base qw(Exporter);

    use Assert::Refute::Build;

    build_refute my_is => sub {
        my ($got, $exp) = @_;
        return $got eq $exp ? '' : to_scalar ($got) ." ne ".to_scalar ($exp);
    }, args => 2, export => 1;
};
BEGIN {
    Foo->import;
};

my $report = refute_and_report {
    my_is 137, 137, "TEST FAILED IS YOU SEE THIS (equal)";
    my_is  42, 137, "TEST FAILED IS YOU SEE THIS (not equal)";
};

is $report->get_sign, "t1Nd", "Signature as expected";
like $report->get_tap, qr/# 42 ne 137/, "Diagnostic present";
note $report->get_tap;

