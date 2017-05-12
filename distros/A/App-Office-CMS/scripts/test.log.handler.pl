#!/usr/bin/perl

use common::sense;

use Log::Handler;

# -----------------------------------------------

my($log) = Log::Handler -> new;

$log -> add
(
	dbi =>
	{
	columns         => [qw/level message/],
	data_source     => 'dbi:Pg:dbname=cms',
	driver          => 'Pg',
	maxlevel        => 'debug',
	message_pattern => [qw/%L %m/],
	message_layout  => '%p %m',
	minlevel        => 'emergency',
	newline         => 0,
	password        => 'cms',
	persistent      => 0,
	table           => 'log',
	user            => 'cms',
	values          => [qw/%level %message/],
	}
);

$log -> log(error => 'msg');

print "errstr: ", $log -> errstr, ". \n";
