#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent ();
use AnyEvent::UserAgent ();


{
	no warnings 'prototype';
	no warnings 'redefine';

	*AnyEvent::HTTP::http_request = sub {
		my $cb = pop();

		$cb->(undef, {
			Status => 590,
			Reason => 'Some warning message',
		});
	};
}

my $ua = AnyEvent::UserAgent->new;
my $cv = AE::cv;

$ua->get('http://example.com/', sub {
	my ($res) = @_;

	ok $res->code == 590;
	is $res->message, 'Some warning message';
	ok $res->header('client-warning');
	is $res->header('client-warning'), $res->message;

	$cv->send();
});

$cv->recv();


done_testing;
