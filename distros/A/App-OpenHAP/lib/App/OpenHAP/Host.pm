# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::OpenHAP::Host;
our $VERSION = '0.1.0';

use IO::Socket::INET;
use Time::HiRes qw(time);

use Fugu::EventLoop;
use Fugu::File;
use Fugu::Log;
use Fugu::Mdnsd;
use Protocol::HAP::Server;
use Protocol::HAP::Store::File;

# App::OpenHAP::Host - the host of the Protocol::HAP engine.
#
# The engine owns the protocol; this module owns everything the
# operating system hands out: the listening socket, per-connection
# reads and writes, the event loop, its timers, the MQTT client, and
# the mDNS advertisement. The engine reaches the outside world only
# through the contracts it was constructed with.

# How much the server reads from a client at a time.
use constant READ_SIZE => 65536;

# The interval between MQTT reconnection attempts, in seconds. A
# broker that is down stays down for a while, and a daemon that
# hammers it helps nobody.
use constant MQTT_RECONNECT_INTERVAL => 30;

sub new ( $class, %args )
{
	# The other fields - the storage, the engine, the MQTT client,
	# the mDNS handle, the loop and the listening socket - appear
	# when their setters and accessors run.
	my $self = bless {
		port         => $args{port} // 51827,
		storage_path => $args{storage_path},

		# Each connection is filed under its session id: the
		# session and its socket together. A fileno index
		# resolves reads to the session id. The kernel reuses
		# descriptors; session ids never repeat.
		connections => {},
		by_fileno   => {},

		mqtt_tick_interval => 0.1,    # MQTT poll interval in seconds

		# For the uptime in a control status. Time::HiRes::time
		# is imported here, and it gives a float; a whole second
		# is all an uptime needs.
		started => int time,
	}, $class;

	$self->{storage} = Protocol::HAP::Store::File->new(
		path   => $self->{storage_path},
		logger => Fugu::Log->default,
	);

	# Build the engine over the host contracts: the storage, the
	# process logger, writes through the connection map, and the
	# one-shot timers of the loop.
	$self->{engine} = Protocol::HAP::Server->new(
		name     => $args{name},
		pin      => $args{pin},
		setup_id => $args{setup_id},
		store    => $self->{storage},
		logger   => Fugu::Log->default,
		output   => sub ( $session, $bytes ) {
			$self->_write( $session, $bytes );
		},
		after => sub ( $seconds, $code ) {
			return $self->loop->after( $seconds, $code );
		},
		cancel => sub ($handle) {
			$self->loop->cancel($handle);
		},
		on_pairing_changed => sub ($paired) {
			$self->_refresh_mdns($paired);
		},
	);

	return $self;
}

# $self->engine:
#	The Protocol::HAP engine of this host.
sub engine ($self)
{
	return $self->{engine};
}

# --- delegation to the engine ---------------------------------------------

sub add_accessory ( $self, $accessory )
{
	$self->{engine}->add_accessory($accessory);

	return;
}

sub is_paired ($self)
{
	return $self->{engine}->is_paired;
}

sub update_config_number ($self)
{
	return $self->{engine}->update_config_number;
}

# $self->mdns_txt_string:
#	The TXT records of the engine, in the format that mdnsd
#	publishes.
sub mdns_txt_string ($self)
{
	return Fugu::Mdnsd::format_txt(
		%{ $self->{engine}->mdns_txt_records } );
}

# --- the connection plumbing ----------------------------------------------

# $self->loop:
#	The event loop of this server. The server makes one on demand,
#	so a caller that only wants to drive timers by hand does not
#	have to build one.
sub loop ($self)
{
	$self->{loop} //= Fugu::EventLoop->new;

	return $self->{loop};
}

# $self->listen:
#	Open the HAP listener and register it with the loop. The method
#	returns the socket. It dies when the port is not available:
#	a HAP server that cannot listen has no reason to run.
sub listen ($self)
{
	return $self->{server} if $self->{server};

	my $server = IO::Socket::INET->new(
		LocalPort => $self->{port},
		Type      => SOCK_STREAM,
		Reuse     => 1,
		Listen    => 10,
	    )
	    or do {
		Fugu::Log->default->error(
			'Cannot create server socket on port %d: %s',
			$self->{port}, $! );
		die "Cannot create server: $!";
	    };

	$self->{server} = $server;
	$self->loop->add_fd( $server, read => sub ($) { $self->_accept } );

	Fugu::Log->default->info( 'OpenHAP server listening on port %d',
		$self->{port} );

	return $server;
}

# $self->run:
#	Serve until the loop stops. The method returns when a signal
#	interrupted the loop or a callback stopped it. Thus the caller
#	runs its own shutdown, and nothing has to exit from inside a
#	signal handler.
sub run ($self)
{
	$self->listen;
	$self->_register_mqtt;
	$self->loop->run;

	Fugu::Log->default->info('OpenHAP server stopped');

	return $self;
}

# $self->shutdown:
#	Close the listener and every client connection. The caller
#	calls this after run returns.
sub shutdown ($self)
{
	for my $conn ( values %{ $self->{connections} } ) {
		my $socket = $conn->{socket};

		$self->loop->remove_fd($socket);
		$socket->close;
	}
	$self->{connections} = {};
	$self->{by_fileno}   = {};

	if ( $self->{server} ) {
		$self->loop->remove_fd( $self->{server} );
		$self->{server}->close;
		$self->{server} = undef;
	}

	return $self;
}

# $self->_accept:
#	Take one connection, open its session, and put it on the loop.
sub _accept ($self)
{
	my $client = $self->{server}->accept or return;

	Fugu::Log->default->info( 'Client connected from %s',
		$client->peerhost );

	my $session = $self->{engine}->session_open;
	$self->{connections}{ $session->id } = {
		session => $session,
		socket  => $client,
	};
	$self->{by_fileno}{ fileno $client } = $session->id;

	$self->loop->add_fd(
		$client,
		read => sub ($fh) {
			$self->_handle_client($fh);
		} );

	return;
}

# $self->_handle_client($sock):
#	Read what arrived and hand it to the engine. The engine
#	returns undef on a fatal condition, and the host closes the
#	connection.
sub _handle_client ( $self, $sock )
{
	# _accept installs the fileno row and the connection together,
	# so a fileno the loop reports always resolves
	my $sid     = $self->{by_fileno}{ fileno $sock } // return;
	my $session = $self->{connections}{$sid}{session};

	my $data  = '';
	my $bytes = $sock->sysread( $data, READ_SIZE );

	if ( !$bytes ) {

		# The connection is closed. The engine releases the
		# pairing lock if this session holds it. Thus an
		# aborted pair-setup cannot block pairing until a
		# restart.
		my $peer = $sock->peerhost // 'unknown';
		$self->_close_client($sock);
		Fugu::Log->default->info( 'Client disconnected from %s',
			$peer );
		return;
	}

	unless ( $self->{engine}->receive( $session, $data ) ) {
		$self->_close_client($sock);
	}

	return;
}

# $self->_write($session, $bytes):
#	The output contract of the engine: write the bytes to the
#	connection that the session is filed under, whole. A
#	controller that closes mid-write raises SIGPIPE, which would
#	kill the daemon; the local guard turns it into an EPIPE that
#	the checked loop reports. A connection the host cannot write
#	is a connection it drops.
sub _write ( $self, $session, $bytes )
{
	my $conn = $self->{connections}{ $session->id } or return;

	local $SIG{PIPE} = 'IGNORE';
	unless ( Fugu::File->_write_all( $conn->{socket}, $bytes, 'session' ) )
	{
		Fugu::Log->default->warning(
			'Dropping session %d: write failed',
			$session->id );
		$self->_close_client( $conn->{socket} );
	}

	return;
}

# $self->_close_client($sock):
#	Drop a client and everything the server kept for it.
sub _close_client ( $self, $sock )
{
	# A write failure inside receive drops the connection before
	# the read path does, so a second close must be a no-op. A
	# closed handle has no fileno, and a handled one has no row.
	my $fileno = fileno $sock                       // return;
	my $sid    = delete $self->{by_fileno}{$fileno} // return;
	my $conn   = delete $self->{connections}{$sid};

	$self->{engine}->session_close( $conn->{session} );

	$self->loop->remove_fd($sock);
	$sock->close;

	return;
}

# --- MQTT -------------------------------------------------------------------

# $self->set_mqtt_client($mqtt):
#	Set the MQTT client for event loop integration
sub set_mqtt_client ( $self, $mqtt )
{
	$self->{mqtt_client} = $mqtt;

	return;
}

# $self->_register_mqtt:
#	Put the MQTT client on the loop: a tick on every interval, and
#	a reconnection attempt on its own slower schedule.
#
#	The two are separate timers because they answer to different
#	clocks. Before this, one poll interval drove both, and the
#	backoff was an epoch comparison inside the pass.
sub _register_mqtt ($self)
{
	return unless $self->{mqtt_client};
	return if $self->{mqtt_timers};

	$self->{mqtt_timers} = [
		$self->loop->every(
			$self->{mqtt_tick_interval},
			sub {
				my $mqtt = $self->{mqtt_client} or return;
				$mqtt->tick(0) if $mqtt->is_connected;
			}
		),
		$self->loop->every(
			MQTT_RECONNECT_INTERVAL,
			sub { $self->_mqtt_retry }
		),
	];

	return;
}

# $self->_mqtt_retry:
#	One reconnection attempt, if the client is down.
sub _mqtt_retry ($self)
{
	my $mqtt = $self->{mqtt_client} or return;
	return if $mqtt->is_connected;

	unless ( $mqtt->reconnect ) {
		Fugu::Log->default->debug(
			'MQTT reconnection attempt failed, will retry');
		return;
	}

	Fugu::Log->default->info('Reconnected to MQTT broker');
	$self->_mqtt_resubscribe_accessories;

	return;
}

# $self->_mqtt_resubscribe_accessories:
#	Resubscribe all accessories to their MQTT topics
sub _mqtt_resubscribe_accessories ($self)
{
	for my $acc ( $self->{engine}->get_bridged_accessories ) {
		eval { $acc->subscribe_mqtt; };
		Fugu::Log->default->error(
			'Failed to resubscribe accessory: %s', $@ )
		    if $@;
	}

	return;
}

# --- mDNS ---------------------------------------------------------------------

# $self->set_mdns($mdns):
#	Set the mDNS registration handle. The engine reports pairing
#	changes through on_pairing_changed, and this host re-advertises
#	the TXT record (HAP-mDNS.md §8).
sub set_mdns ( $self, $mdns )
{
	$self->{mdns} = $mdns;

	return;
}

# $self->_refresh_mdns($paired):
#	Re-advertise the TXT record. The engine already filtered for a
#	real state change.
sub _refresh_mdns ( $self, $paired )
{
	# Never send an update to an unpublished handle. The daemon
	# can start while mdnsd is down. This code runs on the
	# pairing path. A write to a dead socket must not be
	# reachable there.
	return unless $self->{mdns} && $self->{mdns}->is_published;

	if ( $self->{mdns}->update_txt( txt => $self->mdns_txt_string ) ) {
		Fugu::Log->default->info(
			'Pairing state changed, re-advertised mDNS TXT (sf=%d)',
			$paired ? 0 : 1
		);
	}
	else {
		Fugu::Log->default->warning(
			'mDNS TXT update failed: %s',
			$self->{mdns}->error // 'unknown'
		);
	}

	return;
}

# --- control ------------------------------------------------------------------

# $self->control_status:
#	What the server can say about itself, for a control client.
#
#	Nothing here is a secret. The setup code, the broker password,
#	the accessory keys and the controller keys all stay in the
#	daemon. A reply that carried one would put it in the output of
#	a command an operator runs in front of other people.
sub control_status ($self)
{
	my $engine   = $self->{engine};
	my $pairings = $self->{storage}->load_pairings;

	# get_bridged_accessories returns a list, and scalar on a list
	# return gives the last element, not a count
	my @devices = $engine->get_bridged_accessories;

	return {
		name          => $engine->{name},
		port          => $self->{port},
		paired        => $engine->is_paired ? 1 : 0,
		pairings      => scalar keys %$pairings,
		config_number => $engine->get_config_number,
		devices       => scalar @devices,
		connections   => scalar keys %{ $self->{connections} },
		mdns          => $self->{mdns}
		    && $self->{mdns}->is_published ? 'published' : 'absent',
		mqtt => !$self->{mqtt_client} ? 'none'
		: $self->{mqtt_client}->is_connected ? 'connected'
		: 'disconnected',
		started => $self->{started},
	};
}

# $self->control_devices:
#	The accessories on the bridge, for a control client. The
#	bridge itself is not one of them: it carries no device.
sub control_devices ($self)
{
	my @devices;
	for my $accessory ( $self->{engine}->get_bridged_accessories ) {
		push @devices,
		    {
			aid    => $accessory->{aid},
			name   => $accessory->{name},
			model  => $accessory->{model},
			serial => $accessory->{serial},
			class  => ref $accessory,
			topic  => $accessory->{mqtt_topic},
		    };
	}

	return [ sort { $a->{aid} <=> $b->{aid} } @devices ];
}

1;
