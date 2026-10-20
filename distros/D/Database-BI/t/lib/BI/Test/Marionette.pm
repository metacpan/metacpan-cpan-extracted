package BI::Test::Marionette;

# The Marionette client: Firefox's own automation protocol, spoken over TCP in
# its length-prefixed JSON framing.  A test of a page in a browser needs a
# browser, and this is the one already on the machine, with no driver binary to
# install and no non-core Perl module to add.
#
# This is the transport only: connecting, framing, commands and script
# execution.  Starting the browser, giving it a profile and a session, and
# knowing when the page is ready belong to BI::Test::Browser, which is what a
# test file uses.

use strict;
use warnings;

use IO::Select      ();
use IO::Socket::INET ();
use JSON::MaybeXS   ();

# Connect to a browser already listening on a Marionette port.  The caller
# retries while the browser is starting up; a refused connection is a die, not
# a false return, so the error says what happened.
sub new {
	my ($class, %arg) = @_;

	my $port = $arg{port};
	die "BI::Test::Marionette->new() needs a port\n"
		unless defined $port && $port =~ /\A\d+\z/;

	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $port,
		Proto    => 'tcp',
		Timeout  => 10,
	) or die "connect to 127.0.0.1:$port: $!\n";

	my $self = bless {
		sock => $sock,
		buf  => '',
		id   => 0,
		sel  => IO::Select->new($sock),
	}, $class;

	my $hello = $self->_read;
	die "unexpected Marionette greeting\n" unless ref $hello eq 'HASH';
	$self->{hello} = $hello;

	return $self;
}

sub _read {
	my ($self) = @_;

	while ($self->{buf} !~ /:/) {
		$self->{buf} .= $self->_recv;
	}

	my ($length, $rest) = split /:/, $self->{buf}, 2;
	die "bad Marionette frame length\n" unless defined $length && $length =~ /\A\d+\z/;

	while (length $rest < $length) {
		$rest .= $self->_recv;
	}

	$self->{buf} = substr($rest, $length);
	return JSON::MaybeXS::decode_json(substr($rest, 0, $length));
}

sub _recv {
	my ($self) = @_;

	unless ($self->{sel}->can_read(60)) {
		die "timed out waiting for Marionette\n";
	}

	my $chunk = '';
	my $n = sysread($self->{sock}, $chunk, 65536);
	die "Marionette connection closed\n" unless defined $n && $n > 0;

	return $chunk;
}

# One command, its result.  A protocol error dies with the command's name and
# the browser's own error object, which is what a failing test should print.
sub cmd {
	my ($self, $name, $params) = @_;
	$params //= {};

	my $id    = ++$self->{id};
	my $json  = JSON::MaybeXS::encode_json([0, $id, $name, $params]);
	my $frame = length($json) . ':' . $json;

	my $off = 0;
	while ($off < length $frame) {
		my $wrote = syswrite($self->{sock}, $frame, length($frame) - $off, $off);
		die "Marionette write: $!\n" unless defined $wrote;
		$off += $wrote;
	}

	while (1) {
		my $msg = $self->_read;
		next unless ref $msg eq 'ARRAY'
			&& ($msg->[0] // '') eq '1'
			&& ($msg->[1] // '') eq $id;

		die "$name: " . JSON::MaybeXS::encode_json($msg->[2]) . "\n" if $msg->[2];
		return $msg->[3];
	}
}

# Run a script in the page and return the script's value.  A script that
# returns a promise has its result waited for by the browser.
sub js {
	my ($self, $script) = @_;

	return $self->cmd('WebDriver:ExecuteScript' => {
		script => $script,
		args   => [],
	});
}

sub close {
	my ($self) = @_;

	return unless $self->{sock};
	close delete $self->{sock};
	$self->{sel} = undef;

	return;
}

1;
