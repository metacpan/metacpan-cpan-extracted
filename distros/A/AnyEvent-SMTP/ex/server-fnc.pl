#!/usr/bin/env perl

use strict;
use lib::abs '../lib';

use AnyEvent;
use AnyEvent::SMTP::Server 'smtp_server';
use Data::Dumper;

my $cv = AnyEvent->condvar;

smtp_server undef, 2525, sub {
	warn "MAIL=".Dumper shift;
	die;
};

$cv->recv;
