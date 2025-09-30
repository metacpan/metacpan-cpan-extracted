#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Assert::Refute::T::Errors;

use Assert::Refute::Report;

dies_like {
    my $report = Assert::Refute::Report->new;
    $report->plan( "garbage" );
} qr/^Assert::Refute.*Odd number.*\bplan\b/, "odd plan doesn't work";

dies_like {
    my $report = Assert::Refute::Report->new;
    $report->plan( "garbage" => 42 );
} qr/^Assert::Refute.*[Uu]nknown.*\bplan\b.*\bgarbage\b/, "garbage plan doesn't work";

dies_like {
    my $report = Assert::Refute::Report->new;
    $report->plan( tests => "cow moo" );
} qr/^Assert::Refute.*tests => n/, "died & alternative suggested";

dies_like {
    my $report = Assert::Refute::Report->new;
    $report->plan( tests => 1 );
    $report->plan( tests => 2 );
} qr/^Assert::Refute.*plan.*already/, "second plan also dies";

dies_like {
    my $report = Assert::Refute::Report->new;
    $report->ok( 1 ); # pass some test
    $report->plan( tests => 2 );
} qr/^Assert::Refute.*plan.*already/, "second plan also dies";

done_testing;
