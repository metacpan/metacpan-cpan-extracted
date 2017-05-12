#!/usr/bin/perl

package App::PersistentSSH;

use MooseX::POE;
use POE::Wheel::Run;

use namespace::clean -except => 'meta';

our $VERSION = "0.04";

with qw(
	MooseX::Getopt
	MooseX::LogDispatch
);

has host => (
	isa => "Str",
	is  => "rw",
	required => 1,
);

has ssh_verbose => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has ssh => (
	isa => "Str",
	is  => "rw",
	default => "ssh",
);

has ssh_master_opts => (
	isa => 'ArrayRef[Str]',
	is  => "rw",
	default => sub { [qw(-o ControlMaster=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -N)] },
);

has ssh_opts => (
	isa => 'ArrayRef[Str]',
	is  => "rw",
	default => sub { [] },
);

has scutil => (
	isa => "Str",
	is  => "rw",
	default => "scutil",
);

has ipconfig => (
	isa => "Str",
	is  => "rw",
	default => "ipconfig",
);

has _stopping_ssh => (
	isa => "Bool",
	is  => "rw",
);

has _ssh_wheel => (
	isa => "POE::Wheel::Run",
	is  => "rw",
	predicate => "_has_ssh_wheel",
	clearer   => "_clear_ssh_wheel",
	handles => {
		_ssh_pid  => "PID",
		_kill_ssh => "kill",
	},
);

has _scutil_wheel => (
	isa => "POE::Wheel::Run",
	is  => "rw",
	predicate => "_has_scutil_wheel",
	clearer   => "_clear_scutil_wheel",
	handles => { _scutil_pid => "PID" },
);

sub START {
	my ( $self, $kernel ) = @_[OBJECT, KERNEL];
	$kernel->yield("start_scutil");
	$kernel->yield("try_spawn");
}

event network_changed => sub {
	my ( $self, $kernel ) = @_[OBJECT, KERNEL];

	$self->logger->info("network state changed");

	$kernel->yield("try_spawn");
};

event try_spawn => sub {
	my ( $self, $kernel ) = @_[OBJECT, KERNEL];

	if ( $self->is_reachable ) {
		$kernel->yield("start_ssh");
	} else {
		$kernel->yield("stop_ssh");
	}
};

sub is_reachable {
	my ( $self, $host ) = @_;

	$host ||= $self->host;

	# wait for the network interfaces to be configured
	$self->logger->debug("ipconfig wait all");
	system( $self->ipconfig, "waitall" );
	$self->logger->info("ipconfig waitall reports interface is configured");

	# check for reachability
	my $scutil = $self->scutil;
	my $out = `$scutil -r $host`;
	chomp $out;

	$self->logger->debug("scutil -r $host: $out");

	if ( $out =~ /^Reachable/ and not $out =~ /Connection (?:Required|Automatic)/ ) {
		$self->logger->debug("$host reachable");
		return 1;
	} else {
		$self->logger->info("$host not reachable");
		return 0;
	}
}

sub is_running {
	my $self = shift;
	return unless $self->_has_ssh_wheel;
	kill 0 => $self->_ssh_pid;
}

sub create_ssh_args {
	my $self = shift;
	return [ ( $self->ssh_verbose ? "-v" : () ), @{ $self->ssh_master_opts }, @{ $self->ssh_opts }, $self->host ];
}

event spawn_command => sub {
	my ( $self, $kernel, $command, @args ) = @_[OBJECT, KERNEL, ARG0, ARG1 .. $#_];

	my ( $program, $args ) = (
		$self->$command,
		$self->${\"create_${command}_args"},
	);

	$self->logger->info("spawning", join(" ", $program, @$args));
	
	my $wheel = POE::Wheel::Run->new(
		Program     => $program,
		ProgramArgs => $args,

		( map { ucfirst() . 'Event' => "${command}_$_" } qw(
			stdin
			stdout
			stderr
			error
			close
		)),

		( map { $_ . Filter => POE::Filter::Line->new } qw(Stdout Stderr Stdin) ),

		@args,
	);

	$kernel->sig_child( $wheel->PID, "${command}_died" );

	$self->${\"_${command}_wheel"}($wheel);
};

event start_ssh => sub {
	my ( $self, $kernel ) = @_[OBJECT, KERNEL];

	unless ( $self->is_running ) {
		$self->call(spawn_command => "ssh");
		$kernel->sig( INT => "stop_ssh" );
	}
};

event ssh_stderr => sub {
	$_[OBJECT]->logger->warning(@_[ARG0 .. $#_]);
};

event ssh_died => sub {
	my $self = $_[OBJECT];

	$self->_clear_ssh_wheel;

	if ( $self->_stopping_ssh ) {
		$self->_stopping_ssh(0);
		$self->logger->info("ssh stopped");
	} else {
		$self->logger->warning("ssh died")
	}

	$self->yield("try_spawn");
};

event stop_ssh => sub {
	my $self = $_[OBJECT];

	if ( $self->_has_ssh_wheel ) {
		$self->_stopping_ssh(1);
		$self->logger->info("stopping ssh");
		$self->_kill_ssh;
	}
};

sub create_scutil_args {
	my $self = shift;
	return [ ];
}

event start_scutil => sub {
	my $self = $_[OBJECT];

	$self->call( spawn_command => "scutil" );

	$self->_scutil_wheel->put(
		"n.add State:/Network/Global/IPv4",
		"n.watch"
	);
};

event scutil_died => sub {
	my $self = $_[OBJECT];

	$self->logger->warning("scutil died");

	$self->_clear_scutil_wheel;

	$self->yield("start_scutil");
};

event scutil_stderr => sub {
	my ( $self, $kernel, $output ) = @_[OBJECT, KERNEL, ARG0];
	$self->logger->debug("scutil err: $output");
};

event scutil_stdout => sub {
	my ( $self, $kernel, $output ) = @_[OBJECT, KERNEL, ARG0];

	if ( $output =~ m{^\s*changed key \[\d+\] = State:/Network/Global/IPv4} ) {
		$kernel->yield("network_changed");
	} elsif ( $output !~ m{^\s*notification callback} ) {
		$self->logger->debug("scutil out: $output");
	}
};

sub run {
	POE::Kernel->run;
}

__PACKAGE__

__END__

=pod

=head1 NAME

App::PersistentSSH - Kick an F<ssh> control master around on OSX using
F<scutil>

=head1 SYNOPSIS

	% persisshtent --host your.host.com

=head1 DESCRIPTION

This POE component will keep an SSH control master alive, depending on network status.

It uses the OSX command line tool F<scutil> to get notification on changes to
the C<State:/Network/Global/IPv4> configuration key. Whenever this key is changed
C<scutil -r> will be used to check if the specified host is directly reachable
(without creating a connection using e.g. PPP), and if so spawn F<ssh>.

If the host is not reachable, F<ssh> is stopped.

=head1 CONFIGURATION

Add something alongs the lines of

	Host *
		ControlPath /tmp/%r@%h:%p

to your F<ssh_config>, in order to configure the path that the F<ssh> control
master will bind on. C<ControlMaster auto> is not needed.

The advantage over C<ControlMaster auto> is that if you close your initial ssh,
which is the control master under C<auto> all subsequently made connections
will also close. By keeping a daemonized, managed instance of C<ssh> this
problem is avoided.


Use C<ssh -v yourhost> to verify that the connection really is going through
the control master.

You can create a F<launchd> service for this using
L<http://lingon.sourceforge.net/>. I use:

	<key>Disabled</key>
	<false/>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>pasta ssh</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/local/bin/perl</string>
		<string>/Users/nothingmuch/Perl/App-PersistentSSH/bin/persisshtent</string>
		<string>--verbose</string>
		<string>--host</string>
		<string>pasta.woobling.org</string>
	</array>

=head1 ATTRIBUTES

=over 4

=item host

The host to connect to. Must be a valid ipaddress/hostname, not just an ssh
config host entry.

=item ssh_verbose

Pass C<-v> to ssh.

=item ssh_opts

Additional options for ssh, useful for tunnelling etc.

=back

=head1 METHODS

=over 4

=item new

=item new_with_options

Spawn the POE component.

C<new_with_options> comes from L<MooseX::Getopt>.

=item run

Calls L<POE::Kernel/run>.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
