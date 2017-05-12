#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use AnyEvent;
use AnyEvent::SMTP::Server;
use AnyEvent::DNS;
use Data::Dumper;

# !
# ! Don't use this example as production code.
# ! This is only an example.
# ! Real production cases must be more smart
# !

my $cv = AnyEvent->condvar;

my $server = AnyEvent::SMTP::Server->new( port => 2525 );

sub verify {
	my ($s,$con,@args) = @_;
	warn "inner event";
	my $helo = $con->{helo} = "@args";
	# Before replying 250 we check that client truly said us his hostname and that his hostname has reverse lookup.
	AnyEvent::DNS::reverse_lookup $con->{host}, sub {
		if (my $hostname = shift) {
			if (lc $hostname eq lc $helo) {
				$con->ok("I'm ready.");
				$con->new_m();
			} else {
				$con->reply("554 Error: Reverse lookup mispatch");
			}
		} else {
			$con->reply("554 Error: Reverse lookup failed");
		}
	};
	$s->stop_event;
	return;
}

$server->reg_cb(
	ready => sub {
		my $s = shift;
		warn "Server started on $s->{host}:$s->{port} with hostname $s->{hostname}\n";
	},
	before_HELO => \&verify, # For event order see L<Object::Event>
	before_EHLO => \&verify,
	mail => sub {
		my ($s,$mail) = @_;
		warn "Mail=".Dumper $mail;
	},
);

$server->start;

$cv->recv;
