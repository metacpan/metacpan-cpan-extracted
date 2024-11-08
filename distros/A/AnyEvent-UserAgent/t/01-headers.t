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
		my (undef, undef, %opts) = @_;

		ok exists($opts{headers});
		is ref($opts{headers}), 'HASH';
		ok keys(%{$opts{headers}}) == 3;

		ok exists($opts{headers}{'X-Foo'});
		is $opts{headers}{'X-Foo'}, 'bar';
		ok exists($opts{headers}{'User-Agent'});
		ok exists($opts{headers}{'X-Multi'});
		is $opts{headers}{'X-Multi'}, 'foo, bar';

		$cb->('', {Status => 200});
	};
}

my $ua = AnyEvent::UserAgent->new;
my $cv = AE::cv;

$ua->get('http://example.com/', 'X-Foo' => 'bar', 'X-Multi' => 'foo', 'X-Multi' => 'bar', sub { $cv->send(); });
$cv->recv();


done_testing;
