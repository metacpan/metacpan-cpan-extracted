#!/usr/bin/env perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More tests => 9;
use Scalar::Util qw(refaddr);

use Assert::Refute::Report;

my $report = Assert::Refute::Report->new;

is_deeply( $report->context, {}, "Context initialized" );

$report->context->{foo} = 42;

is_deeply( $report->context, {foo => 42}, "Context preserved" );

my $ret = $report->set_context( { bar => 137 } );
is( refaddr($ret), refaddr($report), "Self returned by set_context" );

is_deeply( $report->context, {bar => 137}, "Context overwritten" );

is eval {
    $report->set_context([]);
    1;
}, undef, "non-hash = no go";
like $@, qr/set_context().*HASH/, "Tell that hash is expected";

is_deeply( $report->context, {bar => 137}, "Context still there" );

$report->done_testing; # success
is $report->get_tap, "1..0\n", "No fails = no context appears";

my $fail_rep = Assert::Refute::Report->new;
$fail_rep->set_context( { foo => { bar => 42 } } );
$fail_rep->ok( 0, "Deliberate failure" );
$fail_rep->done_testing;

like $fail_rep->get_tap, qr/# context: foo: \{ *bar *=> *42 *\}/, "Appended context after fail";

note "<report>\n", $fail_rep->get_tap, "</report>";
