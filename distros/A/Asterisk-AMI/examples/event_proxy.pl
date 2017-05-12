#!/usr/bin/perl

#Author: Ryan Bullock
#Version: 0.1
#Description: This provided a very simple event proxy for the asterisk manager interface.

use strict;
use warnings;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Asterisk::AMI;

#Port to listen on
my $port = 5039;

#Delimiters
my $EOL = "\015\012";

my $EOR = $EOL;

#Keep a list of clients
my %clients;

#Connect to asterisk
my $astman = Asterisk::AMI->new(PeerAddr => '127.0.0.1',
				Username => 'admin',
				Secret	=> 'supersecret',
				Events	=> 'on', #Give us something to proxy
				Timeout => 3, #Default timeout for all operations, 3 seconds
				Handlers => { default => \&proxy_event }, #Install default handler
				Keepalive => 60, #Send a keepalive every minute
				on_error => sub { print "Error occured on socket\r\n"; exit; },
				on_timeout => sub { print "Connection to asterisk timed out\r\n"; exit; }
			);

die "Unable to connect to asterisk" unless ($astman);

#Handler for events
sub proxy_event {
	my ($asterisk, $event) = @_;

	#Event string to build and proxy
	my $pevent;

	#Build the proxied event string
	#For now pretend we like we are asterisk and format as such

	#String from {'DATA'}
	my $dstring;

	#DATA in events are usually lines without values
	#something like 'AppData:' but nothing in the value
	#We don't have to send them, but just to be 'compatible' we will
	foreach my $data (@{$event->{'DATA'}}) {
		$dstring .= $data . $EOL;
	}

	$dstring .= $EOR;

	delete $event->{'DATA'};

	while (my ($key, $value) = each(%{$event})) {
		$pevent .= $key . ': ' . $value . $EOL;
	}

	#Stick the DATA fields at the end
	$pevent .= $dstring;

	#Send it to all the clients
	foreach my $handle (values %clients) {
		$handle->push_write($pevent);
	}

	return 1;
}

#Remove a client if they d/c or error
sub remove_client {
	delete $clients{$_[0]->fh};
	$_[0]->destroy;
	return 1;
}

#Handles new connections
sub new_client {
	my ($fh, $host, $port) = @_;

	#Create an AnyEvent handler for the client
	my $handle = new AnyEvent::Handle(	fh => $fh,
						on_error => \&remove_client,
						on_eof => \&remove_client
						);

	#Discard client input
	$handle->push_read( line => sub { return; });

	#Send a greeting
	$handle->push_write('Connected to event proxy.' . "\r\n");

	$clients{$handle} = $handle;
}

#Our server to accept connections
tcp_server undef, $port, \&new_client;

#Start our server
print "Starting Event Proxy\r\n";
AnyEvent::Impl::Perl::loop;
