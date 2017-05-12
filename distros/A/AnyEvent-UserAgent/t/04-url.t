#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use AnyEvent ();
use AnyEvent::UserAgent ();


my $ua = AnyEvent::UserAgent->new;
my $cv = AE::cv;

$ua->get('invalid', sub {
	my ($res) = @_;

	ok $res->code == 599;

	$cv->send();
});
$cv->recv();
