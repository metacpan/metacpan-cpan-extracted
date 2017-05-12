#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use AnyEvent ();
use AnyEvent::UserAgent ();


my $SetCookieHeader = '';

{
	no warnings 'prototype';
	no warnings 'redefine';

	*AnyEvent::HTTP::http_request = sub {
		my $cb = pop();

		$cb->('', {
			Status       => 200,
			Reason       => 'OK',
			'set-cookie' => $SetCookieHeader,
		});
	};
}

my $ua = AnyEvent::UserAgent->new;
my $cv;
my $val;

# One simple cookie
$cv  = AE::cv;
$val = 'key=val; expires=Tue, 19-Jan-2038 03:14:07 GMT; path=/; domain=.example.com';

$SetCookieHeader = $val;
$ua->get('http://example.com/', sub {
	my ($res) = @_;

	is $res->header('set-cookie'), $val;

	$cv->send();
});

$cv->recv();

# Two simple cookies
$val = ['key1=val1; expires=Tue, 19-Jan-2038 03:14:07 GMT; path=/; domain=.example.com',
        'key2=val2; expires=Tue, 19-Jan-2038 03:14:07 GMT; path=/; domain=.example.com'];
$cv  = AE::cv;

$SetCookieHeader = join(',', @$val);
$ua->get('http://example.com/', sub {
	my ($res) = @_;

	cmp_bag [$res->header('set-cookie')], $val;

	$cv->send();
});
$cv->recv();

# One cookie with non-alphanumeric name
$cv  = AE::cv;
$val = 'key1.key2=val; expires=Tue, 19-Jan-2038 03:14:07 GMT; path=/; domain=.example.com';

$SetCookieHeader = $val;
$ua->get('http://example.com/', sub {
	my ($res) = @_;

	is $res->header('set-cookie'), $val;

	$cv->send();
});

$cv->recv();


done_testing;
