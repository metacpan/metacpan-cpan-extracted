#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use AnyEvent;
use AnyEvent::SMTP::Server;
use Data::Dumper;

my $cv = AnyEvent->condvar;

my $server = AnyEvent::SMTP::Server->new( port => 2525 );

$server->reg_cb(
	ready => sub {
		my $s = shift;
		warn "Server started on $s->{host}:$s->{port} with hostname $s->{hostname}\n";
	},
	client => sub {
		my ($s,$con) = @_;
		warn "Client from $con->{host}:$con->{port} connected\n";
	},
	disconnect => sub {
		my ($s,$con) = @_;
		warn "Client from $con->{host}:$con->{port} gone\n";
	},
	mail => sub {
		my ($s,$mail) = @_;
		warn "Mail=".Dumper $mail;
	},
);

$server->start;

$cv->recv;
