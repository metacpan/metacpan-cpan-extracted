# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2024 Dick Olsson <hi@senzilla.io>
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

package App::FuguVM::QMP;
our $VERSION = '0.1.1';

use Fugu::JSONSocket;

# App::FuguVM::QMP - the QEMU Machine Protocol command set.
#
# The transport is Fugu::JSONSocket. This file holds only what is
# true of QMP: the greeting, the capabilities handshake, and the four
# commands that FuguVM uses to manage a VM's lifecycle.

use constant READ_TIMEOUT => 10;

sub new ( $class, $socket_path )
{
	return bless {
		socket => Fugu::JSONSocket->new(
			path     => $socket_path,
			timeout  => READ_TIMEOUT,
			greeting => 1,
		),
	}, $class;
}

# $self->socket_path:
#	Return the QMP socket path.
sub socket_path ($self)
{
	return $self->{socket}->path;
}

# $self->is_available:
#	Report if the socket file is there. QEMU creates it at startup,
#	so its absence means the VM has not started.
sub is_available ($self)
{
	return $self->{socket}->exists;
}

# $self->open_connection:
#	Connect, read the greeting, and leave capabilities negotiation
#	behind. QMP refuses every other command until qmp_capabilities
#	succeeds. The method returns 1 on success and 0 on failure.
sub open_connection ($self)
{
	return 1 if $self->{socket}->is_connected;

	$self->{socket}->connect or return 0;

	my $greeting = $self->{socket}->greeting;
	if ( !defined $greeting || !exists $greeting->{QMP} ) {
		$self->disconnect;
		return 0;
	}

	unless ( defined $self->run_command('qmp_capabilities') ) {
		$self->disconnect;
		return 0;
	}

	return 1;
}

sub disconnect ($self)
{
	$self->{socket}->disconnect;
	return $self;
}

# $self->run_command($command, $arguments):
#	Run one QMP command. The method returns the whole reply, so a
#	caller can tell an error reply from a missing one.
sub run_command ( $self, $command, $arguments = undef )
{
	my %message = ( execute => $command );
	$message{arguments} = $arguments if defined $arguments;

	return $self->{socket}->request( \%message );
}

# $self->query_status:
#	Query the VM running status. The method returns a hashref with
#	the 'running' and 'status' keys.
sub query_status ($self)
{
	my $result = $self->run_command('query-status');
	return if !defined $result || exists $result->{error};

	return $result->{return};
}

# $self->is_running:
#	Check if the VM runs now
sub is_running ($self)
{
	my $status = $self->query_status;
	return 0 if !defined $status;

	return $status->{running} ? 1 : 0;
}

# $self->powerdown:
#	Ask the guest for a controlled shutdown through ACPI
sub powerdown ($self)
{
	my $result = $self->run_command('system_powerdown');

	return defined $result && !exists $result->{error};
}

# $self->quit:
#	Stop the QEMU process immediately
sub quit ($self)
{
	my $result = $self->run_command('quit');
	$self->disconnect;

	return defined $result && !exists $result->{error};
}

1;
