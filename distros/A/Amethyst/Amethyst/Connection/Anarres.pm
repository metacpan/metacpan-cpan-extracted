package Amethyst::Connection::Anarres;

use strict;
use vars qw(@ISA);
use POE;
use Data::Dumper;
use Parse::Lex;
use Amethyst::Connection;
use Amethyst::Message;

@ISA = qw(Amethyst::Connection);

# Offsets into the IST_COMPUTER format for machine readable messages.
sub MS_CLASS	() { 0; }
sub MS_CONTENT	() { 1; }	# Might be removed
sub MS_FORMAT	() { 2; }
sub MS_SOURCE	() { 3; }
sub MS_ARGBASE	() { 4; }

# Token type and value, from Parse::Lex->analyze
sub MT_TYPE		() { 0; }
sub MT_VALUE	() { 1; }

sub unescape_string {
	my ($token, $string) = @_;

	$string =~ s/^"//;
	$string =~ s/"$//;
	$string =~ s/\\a/\a/g;
	$string =~ s/\\n/\n/g;
	$string =~ s/\\r/\r/g;
	$string =~ s/\\b/\b/g;
	$string =~ s/\\t/\t/g;
	$string =~ s/\\t/\t/g;
	# $string =~ s/\\v/\v/g;
	$string =~ s/\\\\/\\/g;
	$string =~ s/\\//g;

	return $string;
}

sub handler_init {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	my @INTEGER = qw(INTEGER [0-9]+);
	my @OBJECT = ('OBJECT', '(?:/[^#:=]+)+(?:#[0-9]+)?(?:=[^:]+)?');
	my @STRING = ('STRING', [ '"', '(?s:[^"\\\\]+|\\\\.)*', '"', ], \&unescape_string);
	my @DTUPLE = qw(DTUPLE [a-z][a-z\.]+[a-z]);
	my @ERROR = ('ERROR', '(?s:.*)', sub { die "Can't analyse $_[1]";});

	my $clexer = new Parse::Lex(
	                @INTEGER,
					@OBJECT,
					@STRING,
					@DTUPLE,
					@ERROR  
						);
	$clexer->skip(':');

	$heap->{ConnectionLexer} = $clexer;

	$heap->{Keepalive} = 60;

	$session->register_state('mung', __PACKAGE__, 'handler_mung');
}

sub handler_login {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	$kernel->yield('write', $heap->{Args}->{Login}, $heap->{Args}->{Password});
	# $kernel->yield('write', 'set PS1=', 'set TERM=none');
	$kernel->yield('write', 'config', 'if', 'prompt', 'mp off', 'q');
	$kernel->yield('write', 'channel -1 all');
	$kernel->yield('write', '');
}

sub handler_logout {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	$kernel->yield('write', 'quit');
}

sub handler_send {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my @messages = @_[ARG0..$#_];
	my @out = ();

	foreach my $message (@messages) {
		my $out;
		
		if ($message->channel eq CHAN_PRIVATE) {
			$out = "tell " . $message->user . " ";
		}
		elsif ($message->channel eq '_world') {
			$out = ($message->action == ACT_EMOTE) ? ":" : "'";
		}
		else {
			if ($heap->{Args}->{Channel}) {
				$out = "channel $heap->{Args}->{Channel} ";
			}
			else {
				$out = "channel  " . $message->channel . " ";
			}
			$out .= ": " if $message->action == ACT_EMOTE;
		}

		$out .= $message->content;

		# print STDERR "Anarres> $out\n";
		push(@out, $out);
	}

	$kernel->yield('write', @out);
}

sub handler_process {
	my ($kernel, $session, $heap, $data) = @_[KERNEL, SESSION, HEAP, ARG0];

	return unless length $data;

	# print STDERR $data, "\n";

	my @tokens;
	
	eval {
		@tokens = $heap->{ConnectionLexer}->analyze($data);
	};

	if ($@) {
		chomp($@);
		print STDERR "Failed to parse '$data': $@\n"
						if $heap->{Debug} > 2;
		return;
	}

	my @data = ();
	while (my ($type, $value) = splice(@tokens, 0, 2)) {
		push(@data, [ $type, $value ] );
	}

	if ($data[MS_CLASS]->[MT_TYPE] ne 'DTUPLE') {
		print STDERR "Message does not start with dtuple: '$data'\n";
		return;
	}
	if ($data[MS_CONTENT]->[MT_TYPE] ne 'STRING') {
		print STDERR "Message does not contain content: '$data'\n";
		return;
	}
	if ($data[MS_FORMAT]->[MT_TYPE] ne 'STRING') {
		print STDERR "Message does not contain format: '$data'\n";
		return;
	}

	$kernel->yield('mung', \@data);
}

sub handler_mung {
	my ($kernel, $session, $heap, $data) = @_[KERNEL, SESSION, HEAP, ARG0];

	my $mclass =  $data->[MS_CLASS]->[MT_VALUE];
	my $content = $data->[MS_CONTENT]->[MT_VALUE];
	my $format =  $data->[MS_FORMAT]->[MT_VALUE];
	my $source =
			$data->[MS_SOURCE]->[MT_TYPE] eq 'OBJECT'
				? $data->[MS_SOURCE]->[MT_VALUE]
				: 'none';

	# print STDERR "Munging $mclass: $content\n";

	my $channel;

	if ($mclass =~ /^(?:channel)\.([a-z]+)/) {
		$channel = $1;

		# return if $channel eq 'cnn';	# Hack!

		$source = lc $data->[MS_ARGBASE]->[MT_VALUE];

		$content = $data->[MS_ARGBASE + 2]->[MT_VALUE];
		$content =~ s/\$N/$source/g;

		$source =~ s/@.*//;	# Do we want to do this?
		$source =~ s/[^a-z]//g;

		# print STDERR "Channel: $source = $content\n";
	}
	elsif ($mclass =~ /^(?:command|verb)\.(?:say|emote)/) {
		$channel = '_world';
	}
	elsif ($mclass =~ /^(?:command|verb)\.(?:tell)/) {
		$channel = CHAN_PRIVATE;
	}
	else {
		$channel = $mclass;
	}

	return if lc $source eq lc $heap->{Args}->{Login};
	return if lc $source =~ /^coffeepot/;

	my $message = new Amethyst::Message(
					Connection	=> $session->ID,
					Channel		=> $channel,
					User		=> $source,
					Action		=> ACT_SAY,
					Content		=> $content,
					Hints		=> { Anarres => $data },
						);

	$kernel->call($heap->{Amethyst}, 'think', $message,$heap->{Brains});
}

sub handler_keepalive {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	# print STDERR "Anarres: keepalive\n";
	$kernel->yield('write', '');
}

1;
