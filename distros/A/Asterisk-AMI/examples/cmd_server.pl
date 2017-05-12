#!/usr/bin/perl

#Author: Ryan Bullock
#Version: 0.2
#Description: This provided a very simple command server for the asterisk manager interface.

use strict;
use warnings;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Asterisk::AMI;

#Port to listen on
my $port = 5080;

#Delimiters
my $EOL = "\015\012";

my $EOR = $EOL;

#Command list;
my $list = 'Command List:' . $EOL;
$list .= 'channels - Displays list of active channels' . $EOL;
$list .= 'mailbox <mailbox> - Displays messages for a mailbox' . $EOL;
$list .= 'hangup <channel> - Hangs up a channel' . $EOL;
$list .= 'quit - Disconnects from server' . $EOL;
$list .= 'list - Displays this list' . $EOL . $EOR;

#Keep a list of clients
my %clients;

#Connect to asterisk
my $astman = Asterisk::AMI->new(PeerAddr => '127.0.0.1',
				Username => 'test',
				Secret	=> 'supersecret',
				Timeout => 3, #Default timeout for all operations, 3 seconds
				Keepalive => 60, #Send a keepalive every minute
				on_error => sub { print "Error occured on socket\r\n"; exit; },
				on_timeout => sub { print "Connection to asterisk timed out\r\n"; exit; },
                                Blocking => 0
			);

die "Unable to connect to asterisk" unless ($astman);

#Callback on mailbox command
sub mailboxcb {
	my ($asterisk, $action, $client) = @_;

	my $id = $action->{'ActionID'};
	
	my $mbstr;

	if ($action->{'GOOD'} && exists $action->{'PARSED'}) {
		while (my ($key, $value) = each %{$action->{'PARSED'}}) {
			$mbstr .= $key . ': '. $value . $EOL;
		}
	} else {
		$mbstr = 'Invalid Mailbox, or command failed' . $EOL;
	}

	$client->push_write($mbstr . $EOR);
}

#Callback on channels command
sub chancb {
	my ($asterisk, $action, $client) = @_;

	my $id = $action->{'ActionID'};
	
	my $chanstr;

	if ($action->{'GOOD'} && exists $action->{'EVENTS'}) {
		foreach my $channel (@{$action->{'EVENTS'}}) {
			$chanstr .= $channel->{'Channel'} . $EOL;
		}
	} else {
		$chanstr = 'No channels active' . $EOL;
	}

	$client->push_write($chanstr . $EOR);
}

#Callback on hangup command
sub hangupcb {
	my ($asterisk, $action, $client) = @_;

	my $id = $action->{'ActionID'};

	my $str;

	if ($action->{'GOOD'}) {
		$str = 'Channel hungup';
	} else {
		$str = 'Failed to hangup channel';
	}	

	$client->push_write($str . $EOL . $EOR);
}

#Remove a client if they d/c or error
sub remove_client {
        delete $clients{$_[0]};
	$_[0]->destroy;
	return 1;
}

#Handle commands from clients
sub client_input {
	my ($handle) = @_;

	my @cmd = split /\s+/,$handle->{rbuf};		
	undef $handle->{rbuf};

	return unless ($cmd[0]);

	if ($cmd[0] eq 'mailbox') {
		$astman->send_action({	Action => 'MailboxCount',
				  	Mailbox => $cmd[1] . '@default' }, \&mailboxcb, undef, $handle);
	} elsif ($cmd[0] eq 'channels') {
		$astman->send_action({Action => 'Status'}, \&chancb, undef, $handle);
	} elsif ($cmd[0] eq 'hangup') {
		$astman->send_action({	Action => 'Hangup',
					Channel => $cmd[1] }, \&hangupcb, undef, $handle);
	} elsif ($cmd[0] eq 'list') {
		$handle->push_write($list);
	} elsif ($cmd[0] eq 'quit') {
		$handle->push_write('Goodbye' . $EOL . $EOR);
		remove_client($handle);
	} else {
		$handle->push_write('Invalid Command' . $EOL . $EOR);
	}
	
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

	#Read what to do on client input
	$handle->on_read(\&client_input);

	#Send a greeting
	$handle->push_write('Connected to command server.' . $EOL);
	$handle->push_write('Enter \'list\' for a list of commands' . $EOL);

        $clients{$handle} = $handle;
}

#Our server to accept connections
tcp_server undef, $port, \&new_client;

#Start our server
print "Starting Command Server\r\n";
AnyEvent::Impl::Perl::loop;
