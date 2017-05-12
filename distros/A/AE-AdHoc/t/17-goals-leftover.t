#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use Data::Dumper;

use AE::AdHoc;
$AE::AdHoc::warnings = 0;

my $timer;
ae_recv {
	$timer = AnyEvent->timer( after => 0, cb => ae_goal("pollute") );
	ae_send->("return right now");
} 0.1;

my $timer2;
ae_recv {
	$timer2 = AnyEvent->timer( after => 0.1, cb => ae_goal("clean") );
} 0.2;

my @keys = sort keys %{ AE::AdHoc->results };
is_deeply( \@keys, ["clean"], "AE results are clean" );
note "Results: ".Dumper( AE::AdHoc->results );

is (scalar @AE::AdHoc::errors, 1, "Exactly 1 error");
like ($AE::AdHoc::errstr, qr(^Leftover.*ae_goal), "Leftover error present");
note "Error was: $AE::AdHoc::errstr";

