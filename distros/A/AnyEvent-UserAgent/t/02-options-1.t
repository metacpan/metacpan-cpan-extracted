#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent ();
use AnyEvent::UserAgent ();


our $TIMEOUT       = 10;
our $MAX_REDIRECTS = 1;

my $cnt = 0;

{
	no warnings 'prototype';
	no warnings 'redefine';

	*AnyEvent::HTTP::http_request = sub {
		my $cb = pop();
		my (undef, undef, %opts) = @_;

		ok $opts{timeout} == $TIMEOUT;
		ok $cnt <= $MAX_REDIRECTS;

		$cnt++;

		my $t; $t = AE::timer 0.1, 0, sub {
			undef($t);
			$cb->('', {
				Status   => 302,
				Location => 'http://example.com/',
			});
		};
	};
}

my $ua = AnyEvent::UserAgent->new(
	inactivity_timeout => $TIMEOUT,
	max_redirects      => $MAX_REDIRECTS,
);
my $cv = AE::cv;

$ua->get('http://example.com/', sub {
	my ($res) = @_;

	ok $res->header('client-warning');

	$cv->send();
});

$ua->inactivity_timeout($TIMEOUT + 1);
$ua->max_redirects($MAX_REDIRECTS + 1);

$cv->recv();


done_testing;
