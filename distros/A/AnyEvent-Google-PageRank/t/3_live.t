#!/usr/bin/env perl

use Test::More;
use AnyEvent;
use AnyEvent::Google::PageRank qw/rank_get/;
use strict;

my $cv = AnyEvent->condvar;
$cv->begin;

$cv->begin;
rank_get "http://www.google.com", sub {
	my ($rank, $headers) = @_;
	
	ok(defined($rank) && $rank =~ /^\d+$/, 'Rank looks like a number')
		or diag "$headers->{Status} - $headers->{Reason}";
	$cv->end;
};

$cv->end;
$cv->recv;

done_testing();
