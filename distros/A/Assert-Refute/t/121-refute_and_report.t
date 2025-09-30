#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Carp;

use Assert::Refute qw(refute_and_report), {
    on_pass => sub { Carp::confess("on_pass callback fired when it shouldn't") },
    on_fail => sub { Carp::confess("on_fail callback fired when it shouldn't") },
};

my $capture;
my $report = refute_and_report {
    $capture = shift;

    $capture->is( 42, 137, "Life is fine" );
};

ok $report->is_done, "Report finished";
is $report->get_sign, "tNd", "1 failed test";

is refaddr $capture, refaddr $report, "Same object inside and outside";

done_testing;
