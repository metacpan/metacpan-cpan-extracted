#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('App::Statsbot') };

my ($time, $reply);

BEGIN {
	no warnings 'redefine';
	*App::Statsbot::_nick_name = sub { 'statsbot' };
	*App::Statsbot::_yield     = sub { $reply = $_[2] };
	*App::Statsbot::_uptime    = sub { $time };
}

sub runtest {
	my ($uptime, $msg, $exp_re) = @_;
	$time = $uptime;
	$reply = 'NOREPLY';
	my @args;
	@args[App::Statsbot::ARG1, App::Statsbot::ARG2] = ('', $msg);
	App::Statsbot::on_public(@args);
	like $reply, $exp_re, "$msg with 0 seconds";
}

my $magicnr = 13980000;

runtest 0, 'hi!', qr/NOREPLY/;
runtest 0, '!help', qr/or !presence/;
runtest 0, ' !help', qr/or !presence/;
runtest 0, 'statsbot:   help', qr/or !presence/;
runtest 0, 'statsbot:   !help', qr/or !presence/;

runtest 0, '!presence mgv', qr/mgv was here 0 hours during the last 1 day/;
runtest 0, '!presence mgv potato', qr/cannot parse timespec: potato/;
runtest $magicnr, '!presence mgv "1 year"', qr/here 3883 hours during/;
runtest $magicnr, '!presence mgv "1 year" 1', qr/here 162 days during/;
runtest $magicnr, '!presence mgv "1 year" 2', qr/here 161 days and 19 hours during/;
runtest $magicnr, '!presence mgv "1 year" 20', qr/here 161 days, 19 hours, and 20 minutes during/;
