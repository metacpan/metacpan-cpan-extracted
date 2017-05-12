package Amethyst::Connection;

use strict;
use Socket qw(AF_INET SOCK_STREAM);
use Data::Dumper;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite
				Filter::Line Driver::SysRW);

sub new {
	my $class = shift;
	my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	die "No name for connection" unless $args->{Name};

	my %states = map { $_ => "handler_$_" } qw(
					_start _stop
					connect connect_ok connect_fail
					disconnect keepalive
					read write error
					init login logout send process
					);

	POE::Session->create(
		package_states	=> [ $class => \%states, ],
		args			=> [ $args ],
			);
}

sub handler__start {
	my ($kernel, $session, $sender, $heap, $args) =
					@_[KERNEL, SESSION, SENDER, HEAP, ARG0];

	$heap->{Args} = $args;
	$heap->{Amethyst} = $sender->ID;

	$kernel->alias_set($args->{Alias}) if $args->{Alias};

	$heap->{Debug} = exists $args->{Debug} ? $args->{Debug} : 0;
	$heap->{Brains} = $args->{Brains} if exists $args->{Brains};
	$heap->{Keepalive} = 0;

	print STDERR "START(Connection $session)\n" if $heap->{Debug} > 7;

	# This has to happen _now_ before the 'connect' trigger
	# happens in Amethyst herself, that being already on the
	# queue.
	$kernel->call($sender, 'register_connection', $args->{Name});
	$kernel->yield('init');
}

sub handler__stop {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	print STDERR "STOP(Connection $session)\n" if $heap->{Debug} > 7;
}

sub handler_read {
	my ($kernel, $heap, $session, $data) = @_[KERNEL, HEAP, SESSION, ARG0];

	warn "<<< $data\n" if $heap->{Debug} > 5;

	$kernel->delay('keepalive', $heap->{Keepalive})
					if $heap->{Keepalive};

	$kernel->yield('process', $data);
}

sub handler_write {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my @data = @_[ARG0 .. $#_];

	my $wheel = $heap->{ReadWrite};

	unless ($wheel) {
		print STDERR "No write wheel\n";
		return;
	}

	foreach my $data (@data) {
		warn ">>> $data\n" if $heap->{Debug} > 5;
		$wheel->put($data);
	}

	$kernel->delay('keepalive', $heap->{Keepalive})
					if $heap->{Keepalive};
}

sub handler_init {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	# Not overriding this is not fatal.
}

sub handler_login {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	die "Login not implemented by connection";
}

sub handler_logout {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
}

sub handler_disconnect {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	$kernel->yield('logout');
}

sub handler_keepalive {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	die "Keepalive requested but not implemented by connection";
}

sub handler_send {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	die "Send not implemented by connection";
}

sub handler_process {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	die "Process not implemented by connection";
}

sub handler_error {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
}

sub handler_connect_ok {
	my ($kernel, $heap, $session, $socket) = @_[KERNEL, HEAP, SESSION, ARG0];

	print STDERR "Connect OK\n" if $heap->{Debug} > 1;

	delete $heap->{SocketFactory};

	my $wheel = POE::Wheel::ReadWrite->new(
					Handle		=> $socket,
					Driver		=> POE::Driver::SysRW->new(),
					Filter		=> POE::Filter::Line->new(
# XXX We should use a telnet_ga as a terminator too.
									InputRegexp		=> qr'\015?\012',
									OutputLiteral	=> "\015\012",
										),
					InputEvent	=> 'read',
					ErrorEvent	=> 'error',
						);

	$heap->{ReadWrite} = $wheel;

	$kernel->yield('login');
}

sub handler_connect_fail {
	my ($kernel, $heap, $session, $socket) = @_[KERNEL, HEAP, SESSION, ARG0];

	print STDERR "Connect failure\n";

	$heap->{ConnectFailures}++;

	if ($heap->{ConnectFailures} > 3) {
		print STDERR "Too many connect failures: Giving up\n";
	}
	else {
		$kernel->alarm('connect', time() + 5);
	}
}

sub handler_connect {
	my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

	my $host = $heap->{Args}->{Host};
	my $port = $heap->{Args}->{Port};
	print STDERR "Connecting to $host:$port\n" if $heap->{Debug} > 1;

	my $wheel = new POE::Wheel::SocketFactory(
					SocketDomain	=> AF_INET,
					SocketType		=> SOCK_STREAM,
					SocketProtocol	=> 'tcp',

					RemoteAddress	=> $host,
					RemotePort		=> $port,

					SuccessEvent	=> 'connect_ok',
					FailureEvent	=> 'connect_fail',
						);

	$heap->{SocketFactory} = $wheel;
}

1;
