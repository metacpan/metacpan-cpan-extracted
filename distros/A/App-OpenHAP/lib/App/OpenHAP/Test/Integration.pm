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

package App::OpenHAP::Test::Integration;
our $VERSION = '0.1.0';

use IO::Socket::INET;
use Time::HiRes qw(sleep);

use App::OpenHAP::Devices;
use Fugu::Config;
use Protocol::HAP::HTTP;
use Fugu::Log;
use Fugu::Process;

use constant {
	DEFAULT_CONFIG    => '/etc/openhapd.conf',
	DEFAULT_HAP_PORT  => 51827,
	DEFAULT_HAP_PIN   => '1995-1018',
	DEFAULT_MQTT_HOST => '127.0.0.1',
	DEFAULT_MQTT_PORT => 1883,
	SYSLOG_FILE       => '/var/log/daemon',
	PIDFILE           => '/var/run/openhapd.pid',
	DB_PATH           => '/var/db/openhapd',

	# The bound on one response the helper accumulates. The
	# accessory database of a bridge is the largest message HAP
	# sends.
	MAX_RESPONSE => 1048576,
};

use constant PAIRINGS_FILE => DB_PATH . '/pairings.db';

# The daemon keeps its counters here: the configuration number, the
# configuration digest, and the failed-attempt count. A wipe of the
# pairing state removes this file too, or the attempt counter of the
# last test survives into the next one.
use constant STATE_FILE => DB_PATH . '/state.json';

sub new ( $class, %options )
{
	my $self = bless {
		config_file => $options{config_file} // DEFAULT_CONFIG,
		hap_port    => $options{hap_port}    // DEFAULT_HAP_PORT,
		mqtt_host   => $options{mqtt_host}   // DEFAULT_MQTT_HOST,
		mqtt_port   => $options{mqtt_port}   // DEFAULT_MQTT_PORT,
		sockets     => [],
		controllers => [],
		mqtt        => undef,
	}, $class;

	return $self;
}

sub setup ($self)
{
	# Make sure the tests run in integration test mode
	die "OPENHAP_INTEGRATION_TEST not set\n"
	    unless $ENV{OPENHAP_INTEGRATION_TEST};

	# The controller drives the accessory's own crypto and pairing
	# code in this process, and that code reports through the
	# process default logger. The default writes to standard error,
	# which is the TAP stream. Install a quiet one.
	Fugu::Log->set_default(
		Fugu::Log->new(
			mode  => 'quiet',
			ident => 'openhap-integration'
		) );

	# Check the system prerequisites
	$self->_verify_system or die "System prerequisites not met\n";

	# Parse the configuration
	$self->_parse_config;

	# Make sure the daemon is running
	$self->ensure_daemon_running or die "Cannot start openhapd daemon\n";

	return 1;
}

sub teardown ($self)
{
	# Close any controller connections
	for my $controller ( @{ $self->{controllers} } ) {
		$controller->close if defined $controller;
	}
	$self->{controllers} = [];

	# Close any open sockets
	$self->close_sockets;

	# Disconnect MQTT if it is connected
	if ( defined $self->{mqtt} ) {
		eval { undef $self->{mqtt}; };
	}

	return 1;
}

# $self->get_controller(%args):
#	Construct an Protocol::HAP::Controller for the configured
#	host/port/PIN. The harness tracks the connection and closes
#	it in teardown.
sub get_controller ( $self, %args )
{
	require Protocol::HAP::Controller;

	# The timeout default is generous: under TCG emulation, one
	# SRP modexp can take many seconds. OPENHAP_TEST_TIMEOUT
	# raises it further.
	my $controller = Protocol::HAP::Controller->new(
		host => '127.0.0.1',
		port => $self->{hap_port},
		pin  => $self->get_config_value('hap_pin') // DEFAULT_HAP_PIN,
		controller_id => 'openhap-test-ctrl',
		timeout       => $ENV{OPENHAP_TEST_TIMEOUT} // 30,
		%args,
	);

	push @{ $self->{controllers} }, $controller;

	return $controller;
}

# $self->ensure_unpaired():
#	Make sure the daemon is unpaired. When stored
#	pairings exist, stop the daemon, wipe the pairing state, and
#	start it again. The wipe keeps the accessory identity. A
#	POST /identify probes the post-condition. It succeeds only
#	while the daemon is unpaired (HAP-HTTP.md §3).
sub ensure_unpaired ($self)
{
	if ( $self->_has_pairings ) {
		$self->ensure_daemon_stopped or return;

		for my $file ( PAIRINGS_FILE, STATE_FILE,
			DB_PATH . '/auth_attempts' )
		{
			next unless -e $file;
			unlink $file or do {
				warn "Cannot remove $file: $!\n";
				return;
			};
		}

		$self->ensure_daemon_running or return;
	}

	return $self->_verify_unpaired;
}

# $self->_has_pairings():
#	Return true when the pairings database holds at least one
#	entry. The daemon leaves comment headers in the file after
#	its first save. Thus a size check cannot tell paired from
#	unpaired. Parse for non-comment lines instead.
sub _has_pairings ($self)
{
	open my $fh, '<', PAIRINGS_FILE or return 0;
	while (<$fh>) {
		next if /^#/ || /^\s*$/;
		close $fh;
		return 1;
	}
	close $fh;

	return 0;
}

# $self->_verify_unpaired():
#	Probe the pairing state with POST /identify. The daemon
#	returns 204 only when unpaired. It returns 400 with
#	{"status":-70401} when still paired (HAP-HTTP.md §3). This
#	sub fails loudly on the paired answer. It closes the probe
#	socket immediately. The socket does not stay registered with
#	the daemon until teardown.
sub _verify_unpaired ($self)
{
	my $before   = scalar @{ $self->{sockets} };
	my $response = $self->http_request( 'POST', '/identify' );
	for my $socket ( splice @{ $self->{sockets} }, $before ) {
		$socket->close if defined $socket;
	}

	unless ( defined $response ) {
		warn "No response to identify probe\n";
		return;
	}

	my ($status) = parse_http_response($response);
	return 1 if defined $status && $status == 204;

	warn sprintf "Daemon not unpaired: identify returned %s\n",
	    $status // 'no status';

	return;
}

# $self->close_sockets():
#	Close and forget every raw socket that http_request opened.
#	Then a probe connection does not stay registered with the
#	daemon until teardown.
sub close_sockets ($self)
{
	for my $socket ( @{ $self->{sockets} } ) {
		$socket->close if defined $socket;
	}
	$self->{sockets} = [];

	return 1;
}

sub http_request ( $self, $method, $path, $body = undef, $headers = {} )
{
	my $socket = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $self->{hap_port},
		Proto    => 'tcp',
		Timeout  => 2,
	);
	return unless defined $socket;

	push @{ $self->{sockets} }, $socket;

	print {$socket} Protocol::HAP::HTTP::build_request(
		method  => $method,
		path    => $path,
		body    => $body,
		headers => { Host => "127.0.0.1:$self->{hap_port}", %$headers },
	);
	$socket->flush;

	# Read until the buffer holds one whole message. A stream
	# socket gives whatever arrived, which is not a message.
	my $response = '';
	while (1) {
		last
		    if Protocol::HAP::HTTP::message_complete( $response,
			max_size => MAX_RESPONSE );

		my $bytes = $socket->sysread( my $chunk, 65536 );
		last unless $bytes;
		$response .= $chunk;
	}

	return $response;
}

sub parse_http_response ($response)
{
	return unless defined $response;

	my $parsed = Protocol::HAP::HTTP::parse_response($response) or return;

	return ( $parsed->{status}, $parsed->{headers}, $parsed->{body} );
}

# status($response):
#	Return the status code of an HTTP response, for the tests
#	that need nothing else from it.
sub status ($response)
{
	my ($status) = parse_http_response($response);

	return $status;
}

# $self->find_char($database, $type, %opt):
#	Find a characteristic by its short type string in a decoded
#	/accessories structure. The walk skips the bridge (aid 1).
#	The option name limits the walk to the accessory whose Name
#	characteristic holds that value. The option ev demands the ev
#	permission. Return (aid, iid, characteristic) on a match.
#	Return the empty list when there is no match.
sub find_char ( $self, $database, $type, %opt )
{
	for my $accessory ( @{ $database->{accessories} // [] } ) {
		next if $accessory->{aid} == 1;
		next
		    if defined $opt{name}
		    && !_accessory_named( $accessory, $opt{name} );
		for my $service ( @{ $accessory->{services} } ) {
			for my $char ( @{ $service->{characteristics} } ) {
				next unless $char->{type} eq $type;
				next
				    if $opt{ev}
				    && !grep { $_ eq 'ev' }
				    @{ $char->{perms} // [] };
				return ( $accessory->{aid}, $char->{iid},
					$char );
			}
		}
	}

	return;
}

# _accessory_named($accessory, $name):
#	Return true when the accessory's Name characteristic (type
#	23) holds $name.
sub _accessory_named ( $accessory, $name )
{
	for my $service ( @{ $accessory->{services} } ) {
		for my $char ( @{ $service->{characteristics} } ) {
			return 1
			    if $char->{type} eq '23'
			    && ( $char->{value} // '' ) eq $name;
		}
	}

	return 0;
}

# $self->wait_value($code, $want, $timeout):
#	Poll $code->() every quarter second, up to $timeout seconds
#	(default 10). A code reference in $want is the predicate over
#	the polled value. Any other $want stops the poll when the
#	value equals it as a string. Return 1 on success. Return
#	undef on the deadline.
sub wait_value ( $self, $code, $want, $timeout = 10 )
{
	my $deadline = time + $timeout;

	while (1) {
		my $value = $code->();
		if ( ref $want eq 'CODE' ) {
			return 1 if $want->($value);
		}
		elsif ( defined $value && "$value" eq "$want" ) {
			return 1;
		}
		return if time >= $deadline;
		sleep 0.25;
	}
}

sub get_config_value ( $self, $key )
{
	return $self->{config}{$key};
}

# $self->get_device_topics():
#	Return the MQTT topic of each configured device that has one.
sub get_device_topics ($self)
{
	return
	    map { $_->{topic} } grep { defined $_->{topic} } $self->get_devices;
}

# $self->get_devices():
#	Return the configured device records as a list of hashes with
#	type, subtype, id, name, and topic.
sub get_devices ($self)
{
	return @{ $self->{devices} // [] };
}

sub ensure_daemon_running ($self)
{
	if ( !_rcctl( 'check', 'openhapd' ) ) {
		_rcctl( 'start', 'openhapd' );
		sleep 1;
		return if !_rcctl( 'check', 'openhapd' );
	}

	# A daemon that runs per rcctl does not serve yet. At
	# startup, the daemon publishes the mDNS advertisement and
	# waits for the mdnsd replies. The HAP listener opens after
	# that. Thus wait for the port, not for a fixed sleep.
	return $self->wait_for_hap_port;
}

# $self->wait_for_hap_port($timeout):
#	Wait until the HAP port accepts connections. Poll every
#	quarter second, up to $timeout seconds. The default is 30
#	seconds, which is generous for TCG emulation. Return 1 when
#	the daemon serves. Return undef on the deadline.
sub wait_for_hap_port ( $self, $timeout = 30 )
{
	my $port     = $self->get_config_value('hap_port') // DEFAULT_HAP_PORT;
	my $deadline = time + $timeout;

	while ( time < $deadline ) {
		my $socket = IO::Socket::INET->new(
			PeerAddr => '127.0.0.1',
			PeerPort => $port,
			Proto    => 'tcp',
			Timeout  => 2,
		);
		if ( defined $socket ) {
			$socket->close;
			return 1;
		}
		sleep 0.25;
	}

	return;
}

sub ensure_daemon_stopped ($self)
{
	return 1 if !_rcctl( 'check', 'openhapd' );

	_rcctl( 'stop', 'openhapd' );
	sleep 1;

	return !_rcctl( 'check', 'openhapd' );
}

# $self->restart_daemon():
#	Restart openhapd through rcctl. Then wait until the HAP port
#	serves again. Return 1 when the daemon serves. Return undef
#	on failure.
sub restart_daemon ($self)
{
	_rcctl( 'restart', 'openhapd' );
	$self->wait_for_hap_port or return;

	return 1;
}

# $self->ensure_mdnsd_running():
#	Make sure that mdnsd runs and continues to run. Start it if
#	necessary. Then check again across a settle window. A
#	point-in-time probe races green when mdnsd starts and then
#	exits shortly after. On failure, emit the captured
#	diagnostics. Then a dead mdnsd is diagnosable from the test
#	output, and the sub does not fail bare.
sub ensure_mdnsd_running ($self)
{
	my $check = sub { _rcctl( 'check', 'mdnsd' ) };

	unless ( $check->() ) {
		_rcctl( 'enable', 'mdnsd' );
		_rcctl( 'start',  'mdnsd' );
	}

	for my $probe ( 1 .. 3 ) {
		sleep 1;
		next if $check->();
		$self->_warn_mdnsd_diagnostics(
			"mdnsd not running at settle probe $probe/3");
		return;
	}

	return 1;
}

# $self->browse():
#	Return one bounded mdnsctl observation of the advertised HAP
#	services.
sub browse ($self)
{
	return `timeout 5 mdnsctl browse hap tcp 2>&1 || true`;
}

# $self->browse_txt():
#	Return one bounded mdnsctl observation with the TXT strings
#	resolved.
sub browse_txt ($self)
{
	return `timeout 5 mdnsctl browse -r hap tcp 2>&1 || true`;
}

# $self->_warn_mdnsd_diagnostics($reason):
#	Emit the captured mdnsd state as warnings for the failure
#	diagnostics. The state holds the rcctl views, the process
#	list, and recent syslog lines.
sub _warn_mdnsd_diagnostics ( $self, $reason )
{
	warn "$reason\n";
	warn 'rcctl get mdnsd: ' . _capture( 'rcctl', 'get', 'mdnsd' );

	my @processes = grep { /\bmdnsd\b/ && !/grep/ }
	    split /\n/, _capture( 'ps', '-axo', 'pid,command' );
	warn 'mdnsd processes: '
	    . ( @processes ? join( "\n", @processes ) . "\n" : "none\n" );

	my @syslog = grep { /mdnsd/ } _read_syslog_tail(200);
	@syslog = splice( @syslog, -20 ) if @syslog > 20;
	warn "recent mdnsd syslog lines:\n"
	    . ( @syslog ? join( "\n", @syslog ) . "\n" : "none\n" );

	return;
}

# _rcctl(@args):
#	Run rcctl and report whether it succeeded. The run captures its
#	output, so a check does not print to the TAP stream.
sub _rcctl (@args)
{
	return Fugu::Process->run( cmd => [ 'rcctl', @args ] )->{success};
}

# _capture(@cmd):
#	Run a command and return what it wrote, for a diagnostic. A
#	command that will not start returns the empty string.
sub _capture (@cmd)
{
	my $result = Fugu::Process->run( cmd => \@cmd );

	return ( $result->{stdout} // '' ) . ( $result->{stderr} // '' );
}

# _read_syslog_tail($lines):
#	Return the last lines of the system log. The read is a plain
#	file read: a shell pipeline of tail and grep would need a
#	shell, and every argument in it would need quoting.
sub _read_syslog_tail ($lines)
{
	open my $fh, '<', SYSLOG_FILE or return ();
	my @all = <$fh>;
	close $fh;

	@all = splice( @all, -$lines ) if @all > $lines;
	chomp @all;

	return @all;
}

sub ensure_mqtt_running ($self)
{
	# Check if the broker is already running
	return 1 if _rcctl( 'check', 'mosquitto' );

	# Try to start the broker
	_rcctl( 'start', 'mosquitto' );
	sleep 1;

	# Make sure the broker started
	return _rcctl( 'check', 'mosquitto' );
}

sub get_mqtt ($self)
{
	return $self->{mqtt} if defined $self->{mqtt};

	# Require Net::MQTT::Simple
	eval { require Net::MQTT::Simple; };
	return if $@;

	# Make sure the broker is running
	return unless $self->ensure_mqtt_running;

	# Create the connection
	eval {
		$self->{mqtt} = Net::MQTT::Simple->new(
			"$self->{mqtt_host}:$self->{mqtt_port}");
	};

	return $self->{mqtt};
}

sub _verify_system ($self)
{
	# Check the required binaries
	return unless -x '/usr/sbin/rcctl';
	return unless -x '/usr/local/bin/openhapd';
	return unless -x '/usr/local/bin/hapctl';

	# Check that the configuration exists
	return unless -f $self->{config_file};
	return unless -r $self->{config_file};

	# Check that the system user exists
	return
	    unless Fugu::Process->run( cmd => [ 'id', '_openhap' ] )->{success};

	# Check that the data directory exists
	return unless -d '/var/db/openhapd';

	return 1;
}

# $self->_parse_config:
#	Read the daemon's own configuration through the parser the
#	daemon uses, and the device blocks through the reader the
#	daemon uses. A second parser here would let the test agree
#	with itself while it disagreed with openhapd.
sub _parse_config ($self)
{
	my $config = Fugu::Config->new( file => $self->{config_file} );
	$config->load or return;

	my %settings = map { $_ => $config->get($_) } $config->setting_names;

	$self->{hap_port} = $settings{hap_port} if defined $settings{hap_port};
	$self->{config}   = \%settings;
	$self->{devices}  = [ App::OpenHAP::Devices->devices($config) ];

	return 1;
}

1;
