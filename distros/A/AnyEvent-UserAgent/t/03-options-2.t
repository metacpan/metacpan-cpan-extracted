#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use AnyEvent ();
use AnyEvent::UserAgent ();
use HTTP::Request::Common ();


{
	no warnings 'prototype';
	no warnings 'redefine';

	*AnyEvent::HTTP::http_request = sub {
		my $cb = pop();
		my (undef, undef, %opts) = @_;

		ok exists($opts{persistent});
		ok $opts{persistent} == 1;
		ok !exists($opts{foo});

		$cb->('', {Status => 200});
	};
}

my $ua = AnyEvent::UserAgent->new;
my $cv = AE::cv;

$ua->request(
	HTTP::Request::Common::GET('http://example.com/'),
	foo        => 'bar',
	persistent => 1,
	sub {
		$cv->send();
	}
);
$cv->recv();


done_testing;
