#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More;
use lib::abs '../lib';
use AnyEvent::Impl::Perl;
BEGIN {
	my @modules = qw(AnyEvent::SMTP AnyEvent::SMTP::Client AnyEvent::SMTP::Server);
	plan tests => scalar( @modules );
	use_ok $_ for @modules;
};
diag( "Testing AnyEvent::SMTP $AnyEvent::SMTP::VERSION, using AnyEvent $AnyEvent::VERSION, Perl $], $^X" );
