package Amethyst::Brain::BarWench;

use strict;
use vars qw(@ISA);
use URI;
use Amethyst::Brain;
use Amethyst::Message;

@ISA = qw(Amethyst::Brain);

sub reply_to {
	my $self = shift;
	my $message = $self->SUPER::reply_to(@_);
	# $message->channel('spam');
	return $message;
}

sub init {
	my $self = shift;

	my %funcs = map { $_ => \&{"action_$_"} } qw(
					help beer caffeine coffee beat pebkac sex npi
					fuckup pissybeer base http hotornot jobs
					rtfs rtfm rtfc
						);

	$self->{Funcs} = \%funcs;

	$self->{Http} = [ ];
	$self->{Hotornot} = [ ];
	$self->{Jobs} = [ ];
	$self->{HttpHash} = { };
}

sub record_http {
	my ($self, $message) = @_;

	my $content = $message->content;

	return undef if $content =~ /Recorded/;

	my @http = ($content =~ m,(http(?:s)?://[^/]\S*),g);

	@http = map { URI->new($_)->canonical->as_string } @http;

	foreach my $url (@http) {
		next if $self->{HttpHash}->{$url};

		my $old = undef;
		my $new = [ $url, $message->user ];

		$self->{HttpHash}->{$url} = 1;

		if ($url =~ m/hotornot/) {
			push(@{ $self->{Hotornot} }, $new);
			$old = shift(@{ $self->{Hotornot} })
							if @{$self->{Hotornot}} > 10;
		}
		else {
			push(@{ $self->{Http} }, $new);
			$old = shift(@{ $self->{Http} })
							if @{$self->{Http}} > 10;
		}

		if ($content =~ m/job/i) {
			push(@{ $self->{Jobs} }, $new);
			$old = shift(@{ $self->{Jobs} })
							if @{$self->{Jobs}} > 10;
		}

		delete $self->{HttpHash}->{$old->[0]} if $old;
	}
}

sub think {
	my $self = shift;
	my $message = shift;

	my $content = $message->content;

	# print STDERR "Content $content\n";

	$self->record_http($message);

	return undef unless $content =~ /^!([A-Za-z]*)(?:\s+(.*))?$/;

	my $command = $1;
	my $arg = defined $2 ? $2 : '';

	# print STDERR "Command $command\n";

	if (exists $self->{Funcs}->{$command}) {
		print STDERR "BarWench: $command $arg\n";
		return $self->{Funcs}->{$command}->(
						$self, $message,
						$command, $arg);
	}

	return undef;
}

sub action_autolart {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user;
	return $self->action_lart($message, $command, $arg);
}

sub action_base {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"intones, \"ALL YOUR BASE ARE BELONG TO US\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_beat {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message, "beats $arg with a stick.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_beer {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message, "pours a beer for $arg.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_caffeine {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message,
					"posts a package of pure caffeine to $arg.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_coffee {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message,
					"pours a steaming hot coffee for $arg.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_fuckup {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"mutters, \"Ah, I see the fuckup " .
					"fairy has visited us again.\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_help {
	my ($self, $message, $command, $arg) = @_;
	my @commands = map { "!$_" } sort keys %{$self->{Funcs}};
	my $reply = $self->reply_to($message,
					"BarWench module for Amethyst: " .
					"Commands are " . join(", ", @commands));
	$reply->send;
	return 1;
}

sub action_hotornot {
	my ($self, $message, $command, $arg) = @_;
	my $reply;

	my @data = @{ $self->{Hotornot} };
	if (@data) {
		@data = map { "(" . $_->[1] . ") " . $_->[0] } @data;
		foreach my $data (@data) {
			$reply = $self->reply_to($message, $data);
			$reply->send;
		}
	}
	else {
		$reply = $self->reply_to($message, "No recorded URLs.");
		$reply->send;
	}
	return 1;
}

sub action_http {
	my ($self, $message, $command, $arg) = @_;
	my $reply;

	my @data = @{ $self->{Http} };
	if (@data) {
		@data = map { "(" . $_->[1] . ") " . $_->[0] } @data;
		foreach my $data (@data) {
			$reply = $self->reply_to($message, $data);
			$reply->send;
		}
	}
	else {
		$reply = $self->reply_to($message, "No recorded URLs.");
		$reply->send;
	}
	return 1;
}

sub action_jobs {
	my ($self, $message, $command, $arg) = @_;
	my $reply;

	my @data = @{ $self->{Jobs} };
	if (@data) {
		@data = map { "(" . $_->[1] . ") " . $_->[0] } @data;
		foreach my $data (@data) {
			$reply = $self->reply_to($message, $data);
			$reply->send;
		}
	}
	else {
		$reply = $self->reply_to($message, "No recorded jobs.");
		$reply->send;
	}
	return 1;
}

sub action_lart {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message,
					"applies a hefty LARTing session to $arg.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_npi {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"mutters, \"Not Plugged In(tm)\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_pebkac {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"mutters, \"Problem exists between " .
					"keyboard and chair.\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_pissybeer {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user unless length $arg;
	my $reply = $self->reply_to($message,
					"pours a weak pissy beer for $arg.");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_rtfc {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"screams, \"Read the fucking code!\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_rtfm {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"screams, \"Read the fucking manual!\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_rtfs {
	my ($self, $message, $command, $arg) = @_;
	my $reply = $self->reply_to($message,
					"screams, \"Read the fucking source!\"");
	$reply->action(ACT_EMOTE);
	$reply->send;
	return 1;
}

sub action_sex {
	my ($self, $message, $command, $arg) = @_;
	$arg = $message->user;
	return $self->action_beat($message, $command, $arg);
}

1;
