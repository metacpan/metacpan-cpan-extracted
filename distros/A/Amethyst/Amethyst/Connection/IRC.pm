package Amethyst::Connection::IRC;

use strict;
use vars qw(@ISA);
use Data::Dumper;
use POE;
use POE::Component::IRC;
use Parse::Lex;
use Amethyst::Connection;
use Amethyst::Message;

@ISA = qw(Amethyst::Connection);

sub handler_init {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	print STDERR "Init IRC\n";

	my @events = qw(
		irc_connected irc_socketerr irc_001
		irc_public irc_msg
		irc_ctcp_action
		process send
			);
	foreach my $event (@events) {
		$session->register_state($event, __PACKAGE__, "handler_$event");
	}

	my $ircalias = $heap->{Args}->{ClientAlias} || 'amethyst irc';

	my $client = new POE::Component::IRC($ircalias);
	$heap->{Client} = $client->ID;

	print STDERR "Started IRC client " . $heap->{Client} . "\n";

	$kernel->post($heap->{Client}, 'register',
					qw(001 public msg ctcp_action));
}

sub handler_connect {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	local *::args = $heap->{Args};
	
	my $nick = $::args{Nick} || 'Amethyst';
	my $server = $::args{Server} || 'london.rhizomatic.net';
	my $port = $::args{Port} || 6667;
	my $username = $::args{Username} || 'amethyst';
	my $ircname = $::args{Ircname} || 'Amethyst by Shevek';

	$kernel->post($heap->{Client}, 'connect', {
					Nick		=> $nick,
					Server		=> $server,
					Port		=> $port,
					Username	=> $username,
					Ircname		=> $ircname,
						} );
}

sub handler_disconnect {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	$kernel->post($heap->{Client}, 'quit', 'Received quit signal');
}

sub handler_send {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my @messages = @_[ARG0..$#_];
	my @out = ();

	foreach my $message (@messages) {
		my $channel = $message->channel;
		$channel =~ s/^#*/#/;
#		print STDERR "$heap->{Client} PRIVMSG " . $channel
#						. ": " . $message->content . "\n";
		if ($message->action == ACT_EMOTE) {
			# Work out how to do actions!
			$kernel->post($heap->{Client}, 'ctcp',
							$channel, "ACTION " .  $message->content);
		}
		else {
			$kernel->post($heap->{Client}, 'privmsg',
							$channel, $message->content);
		}
	}
}

sub handler_irc_connected {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	print STDERR "IRC: Connected to IRC\n";

#	if ($heap->{Args}->{Channels}) {
#		my @channels = @{ $heap->{Args}->{Channels} };
#		foreach my $channel (@channels) {
#			print STDERR "IRC: Joining $channel\n";
#			$channel =~ s/^#*/#/;
#			$kernel->post($heap->{Client}, 'join', $channel);
#		}
#	}

}

sub handler_irc_001 {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	print STDERR "IRC: Got IRC 001\n";

	if ($heap->{Args}->{Channels}) {
		my @channels = @{ $heap->{Args}->{Channels} };
		foreach my $channel (@channels) {
			print STDERR "IRC: Joining $channel\n";
			$channel =~ s/^#*/#/;
			$kernel->post($heap->{Client}, 'join', $channel);
		}
	}
}

sub handler_irc_socketerr {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
}

# Unsuprisingly, much of this code needs refactoring.

sub handler_process {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my ($sender, $channel, $action, $text) = @_[ARG0..ARG3];

	$sender =~ s/!.*//;

	# IRC doesn't send our messages back to us.

	my $message = new Amethyst::Message(
					Connection	=> $session->ID,
					Channel		=> $channel,
					User		=> $sender,
					Action		=> $action,
					Content		=> $text,
						);

	$kernel->post($heap->{Amethyst}, 'think', $message,$heap->{Brains});
}

sub handler_irc_public {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my ($sender, $channels, $text) = @_[ARG0..ARG2];

	# print STDERR "$sender: $text\n";

	$kernel->post($session, 'process',
			$sender, $channels->[0], ACT_SAY, $text);
}

sub handler_irc_msg {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my ($sender, $recips, $text) = @_[ARG0..ARG2];

	# print STDERR "$sender (private): $text\n";

	$kernel->post($session, 'process',
			$sender, CHAN_PRIVATE, ACT_SAY, $text);
}

sub handler_irc_ctcp_action {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my ($sender, $channels, $text) = @_[ARG0..ARG2];

	# print STDERR "$sender (action) $text\n";

	$kernel->post($session, 'process',
			$sender, $channels->[0], ACT_EMOTE, $text);
}

1;
