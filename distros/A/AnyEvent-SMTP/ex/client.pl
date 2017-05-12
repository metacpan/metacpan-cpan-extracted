#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use AnyEvent;
use AnyEvent::SMTP::Client 'sendmail';

my $cv = AnyEvent->condvar;
$cv->begin(sub{ $cv->send });

sendmail
	# debug => 1, # connection debug
	timeout => 10,
	from => 'mons@cpan.org',
	to   => 'mons@cpan.org', # SMTP host will be detected from addres by MX record
	data => 'Test message '.time().' '.$$,
	cv   => $cv,             # on passed cv will be called ->begin at the beginning and ->end on finish
	cb   => sub {
		if (my $ok = shift) {
			warn "Successfully sent";
		}
		if (my $err = shift) {
			warn "Failed to send: $err";
		}
	}
;

sendmail # From/To/Message - like in Mail::Sendmail
	# debug   => 1, # connection debug
	host    => 'localhost', port => 2525, # use concrete SMTP host for sending
	From    => 'mons@cpan.org',
	To      => [ 'mons@rambler-co.ru', 'inthrax@gmail.com' ], # multiple recipients
	Message => 'Test message '.time().' '.$$,
	cv => $cv,
	cb => sub {
		if (my $ok = shift) {
			warn "Successfully sent: ".join( ', ', keys %$ok )
		}
		if (my $err = shift) {
			warn "Failed to send: ".join( ', ',keys %$err )
		}
	}
;

$cv->end;
$cv->recv;
