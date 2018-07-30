#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Assert::Refute::Report;

use Test::More;

my $report = Assert::Refute::Report->new;
$report->diag( "premature message" );
$report->refute( 0, undef );
$report->refute( 0, 0 );
$report->refute( 0, "passing test" );
$report->refute( 1, "failing test" );
$report->refute( "reason", "test with reason" );
$report->refute( [ {foo => 42}, "bar"], "multiline reason" );
$report->done_testing;

is $report->get_sign, "t3NNNd", "Report is consistent";

note "<report>\n", $report->get_tap, "</report>";

my @diag_from_tap = grep { /^#/ } split /\n/, $report->get_tap;
my @diag_by_hand  = map { "# $_" } map { @$_ }
    map { $report->get_result_details( $_ )->{diag} } 0 .. $report->get_count, -1;

subtest "diag is the same both ways" => sub {
    foreach ( 1 .. @diag_from_tap ) {
        is $diag_from_tap[$_], $diag_by_hand[$_], "Line $_ matches";
    };
    is scalar @diag_by_hand, scalar @diag_from_tap, "Number or lines equal";
};

my @names_from_tap = grep { !/^#/ } split /\n/, $report->get_tap;
my @names_by_hand  = map {
    ($_->{ok} ? "ok " : "not ok ")
        . $_->{number}
        . ($_->{name} ? " - $_->{name}" : "" )
} map {
    $report->get_result_details( $_ );
} 1 .. $report->get_count;
push @names_by_hand, "1..".$report->get_count;

subtest "test names & numbers" => sub {
    foreach ( 1 .. @names_from_tap ) {
        is $names_from_tap[$_], $names_by_hand[$_], "Line $_ matches";
    };
    is scalar @names_by_hand, scalar @names_from_tap, "Number or lines equal";
};

done_testing;

