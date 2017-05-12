#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent ();
use AnyEvent::UserAgent ();


our $TIMEOUT = 0.5;

{
	no warnings 'prototype';
	no warnings 'redefine';

	*AnyEvent::HTTP::http_request = sub {
		my $cb = pop();

		my $t; $t = AE::timer $TIMEOUT + 10, 0, sub {
			undef($t);
			$cb->('', {
				Status => 200,
				Reason => 'OK',
			});
		};
	};
}

my $ua = AnyEvent::UserAgent->new(
	request_timeout => $TIMEOUT,
);
my $cv = AE::cv;

$ua->get('http://example.com/', sub {
	my ($res) = @_;

	ok $res->code == 597;
	is $res->message, 'Request timeout';

	$cv->send();
});

$cv->recv();


done_testing;
