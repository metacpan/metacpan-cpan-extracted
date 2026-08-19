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

package App::FuguVM::State;
our $VERSION = '0.1.1';

use Fugu::File;
use Fugu::Log;
use Fugu::Pidfile;
use Fugu::StateFile;

# App::FuguVM::State - what FuguVM remembers about one VM between runs.
#
# The JSON blob rides on Fugu::StateFile. The two process IDs ride on
# Fugu::Pidfile, which locks before it truncates and reaps a zombie
# before it answers "running".
#
# The module is persistence only. It starts nothing and stops nothing:
# the proxy lifecycle belongs to App::FuguVM::Guest, which is what removed the
# require cycle between this module and App::FuguVM::Proxy.

sub new ( $class, $state_dir, $vm_name, %opts )
{
	# The name becomes a directory under the state directory. A
	# name with a separator in it would put that directory
	# somewhere else.
	unless ( Fugu::File->valid_name($vm_name) ) {
		Fugu::Log->default->error( 'Not a usable VM name: %s',
			$vm_name // '(none)' );
		return;
	}

	my $vm_state_dir = "$state_dir/$vm_name";

	my $self = bless {
		state_dir    => $state_dir,
		vm_name      => $vm_name,
		vm_state_dir => $vm_state_dir,
		disk_path    => "$vm_state_dir/disk.qcow2",
		vm_pid => Fugu::Pidfile->new( path => "$vm_state_dir/vm.pid" ),
		proxy_pid =>
		    Fugu::Pidfile->new( path => "$vm_state_dir/proxy.pid" ),
		store => Fugu::StateFile->new(
			path => "$vm_state_dir/status",
			mode => 0600,
		),
	}, $class;

	Fugu::File->ensure_dir($vm_state_dir) or return;
	$self->load;

	return $self;
}

sub load ($self)
{
	$self->{store}->load;
	return $self;
}

sub save ($self)
{
	$self->{store}->save;
	return $self;
}

# $self->store:
#	Return the state store. App::FuguVM::Guest gives it to the proxy, which
#	keeps its port there.
sub store ($self)
{
	return $self->{store};
}

# $self->state_dir:
#	Return the directory that holds every VM's state, not this
#	VM's own. App::FuguVM::Disk keys its paths by VM name under it.
sub state_dir ($self)
{
	return $self->{state_dir};
}

# $self->vm_pidfile:
#	Return the PID file of the QEMU process. QEMU writes it itself,
#	through its -pidfile option.
sub vm_pidfile ($self)
{
	return $self->{vm_pid};
}

# $self->proxy_pidfile:
#	Return the PID file of the proxy child. App::FuguVM::Guest gives it to
#	the proxy supervisor.
sub proxy_pidfile ($self)
{
	return $self->{proxy_pid};
}

# VM PID management. QEMU writes the pid file itself, so the module
# only reads and clears it.
sub get_vm_pid ($self)
{
	return $self->{vm_pid}->read_pid;
}

sub clear_vm_pid ($self)
{
	$self->{vm_pid}->remove;
	return $self;
}

# $self->is_vm_running:
#	Report if the QEMU process is alive. A QEMU that became a
#	zombie is not running: the check reaps it and says so.
sub is_vm_running ($self)
{
	return $self->{vm_pid}->is_running ? 1 : 0;
}

# Disk state
sub disk_path ($self)
{
	return $self->{disk_path};
}

sub disk_exists ($self)
{
	return -f $self->{disk_path};
}

# Installation state
sub is_installed ($self)
{
	return $self->{store}->get('installed') ? 1 : 0;
}

sub mark_installed ($self)
{
	$self->{store}->data->{installed}    = 1;
	$self->{store}->data->{installed_at} = time;
	$self->{store}->save;

	return $self;
}

# Root password management. The state stores the password for the
# initial setup. The store writes at mode 0600.
sub set_root_password ( $self, $password )
{
	$self->{store}->set( root_password => $password );
	return $self;
}

sub get_root_password ($self)
{
	return $self->{store}->get('root_password');
}

# SSH key installation state
# The state tracks which SSH key is installed. Thus the system can
# detect when the configured SSH key changed. Then it automatically
# installs the new key.
sub mark_ssh_key_installed ( $self, $ssh_pubkey = undef )
{
	my $data = $self->{store}->data;
	$data->{ssh_key_installed}    = 1;
	$data->{ssh_key_installed_at} = time;
	$data->{installed_ssh_pubkey} = $ssh_pubkey if defined $ssh_pubkey;
	$self->{store}->save;

	return $self;
}

sub get_installed_ssh_pubkey ($self)
{
	return $self->{store}->get('installed_ssh_pubkey');
}

sub vm_state_dir ($self)
{
	return $self->{vm_state_dir};
}

sub vm_name ($self)
{
	return $self->{vm_name};
}

sub data ($self)
{
	return $self->{store}->data;
}

# Shutdown state tracking
# The state records whether the VM was shut down cleanly. This detects
# the risk of filesystem corruption.

sub mark_clean_shutdown ($self)
{
	my $data = $self->{store}->data;
	$data->{shutdown_clean} = 1;
	$data->{shutdown_at}    = time;
	delete $data->{running};
	$self->{store}->save;

	return $self;
}

sub mark_unclean_shutdown ($self)
{
	my $data = $self->{store}->data;
	$data->{shutdown_clean} = 0;
	$data->{shutdown_at}    = time;
	delete $data->{running};
	$self->{store}->save;

	return $self;
}

sub mark_running ($self)
{
	my $data = $self->{store}->data;
	$data->{running}    = 1;
	$data->{started_at} = time;
	delete $data->{shutdown_clean};
	$self->{store}->save;

	return $self;
}

sub was_unclean_shutdown ($self)
{
	my $data = $self->{store}->data;

	# The state explicitly marks the shutdown as unclean
	if ( exists $data->{shutdown_clean} && !$data->{shutdown_clean} ) {
		return 1;
	}

	# The state says running, but the VM process is dead. Thus the
	# VM crashed or was killed.
	if ( $data->{running} && !$self->is_vm_running ) {
		return 1;
	}

	return 0;
}

sub clear_shutdown_state ($self)
{
	my $data = $self->{store}->data;
	delete $data->{shutdown_clean};
	delete $data->{running};
	$self->{store}->save;

	return $self;
}

1;
