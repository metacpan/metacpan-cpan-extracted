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

# App::FuguVM::Guest - the lifecycle of one OpenBSD guest.
#
# The module creates, starts, waits for, stops, and destroys one
# guest. It drives QEMU over QMP, so the lifecycle verbs report what
# the hypervisor says and not what a sleep guessed.

package App::FuguVM::Guest;
our $VERSION = '0.1.1';

use App::FuguVM::Miniroot;
use App::FuguVM::DiskCache;
use App::FuguVM::Disk;
use App::FuguVM::Console;
use App::FuguVM::Proxy;
use App::FuguVM::QMP;

use Fugu::Random;
use Fugu::Process;
use Fugu::SSH;
use Fugu::Timeout;

use constant {
	EXIT_SUCCESS    => 0,
	EXIT_ERROR      => 1,
	EXIT_VM_RUNNING => 5,
	EXIT_TIMEOUT    => 7,

	# Fixed configuration for OpenBSD arm64 guests
	QEMU_BINARY    => 'qemu-system-aarch64',
	MEMORY_DEFAULT => '1G',
	CPU_COUNT      => 2,

	# The guest CPU model under TCG emulation. TCG does not use host
	# passthrough.
	TCG_CPU => 'cortex-a57',
};

sub new ( $class, %args )
{
	my $self = bless {
		config   => $args{config},
		state    => $args{state},
		log      => $args{log},
		emulate  => $args{emulate}  // 0,
		no_cache => $args{no_cache} // 0,
	}, $class;

	return $self;
}

# The operation is idempotent. It makes sure that the VM runs.
sub up ($self)
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	# Check if the VM already runs
	if ( $self->_is_running ) {

		# The VM runs, but the SSH key is not installed or is not
		# current. This occurs when the first boot failed, or when
		# the key changed in the configuration.
		if ( $state->is_installed && $self->_needs_ssh_key_update ) {
			return $self->_complete_ssh_setup;
		}

		$log->info("VM '$config->{name}' is already running");
		return EXIT_SUCCESS;
	}

	# Verify the backing chain of the disk before other checks read
	# the disk. A base image that is missing from the cache is not
	# corruption. The unclean-shutdown check below would report it as
	# corruption and recommend 'fuguvm disk repair'. That command
	# cannot make a missing backing file again.
	if ( $state->disk_exists && !$self->_verify_backing_chain ) {
		return EXIT_ERROR;
	}

	# Check for an unclean shutdown. Then check the disk integrity.
	if ( $state->was_unclean_shutdown ) {
		$log->warning("Detected unclean shutdown, checking disk...");
		my $disk  = App::FuguVM::Disk->new( $state->state_dir );
		my $check = $disk->check( $config->{name} );

		if ( defined $check && $check->{status} ne 'ok' ) {
			$log->error(
"Disk corruption detected. Run 'fuguvm disk repair' to fix"
			);
			return EXIT_ERROR;
		}
		$state->clear_shutdown_state;
	}

	# Derive the installed-image cache key one time only, before the
	# installer runs. key() hashes install.exp at call time. An
	# install takes tens of minutes. A key derived again after the
	# install would publish the image the OLD installer made under
	# the NEW digest.
	my $cache     = $self->_image_cache;
	my $cache_key = defined $cache ? $cache->key($config) : undef;

	# Restore from the installed-image cache when there is no disk yet
	if ( !$state->disk_exists && defined $cache_key ) {
		$self->_cache_restore( $cache, $cache_key );
	}

	# Start the caching proxy for the VM installation. The VM
	# downloads its packages through the proxy. The first run also
	# uses the proxy to download the miniroot image.
	my $proxy = $self->_ensure_proxy;
	my $proxy_vm_url;    # For downloads inside the OpenBSD guest

	if ( defined $proxy ) {
		$proxy_vm_url = $proxy->guest_url;
		$log->info("Proxy started: $proxy_vm_url");
	}
	else {
		$log->info(
			"Proxy not available, VM downloads will not be cached");
	}

	# Make sure that the miniroot is available. Download it through
	# the proxy if necessary. Only the installer boots the miniroot.
	# An installed system boots its own disk, whether it was freshly
	# installed or restored from the image cache. Such a system must
	# not fail here because the miniroot was pruned.
	my $image_path;

	if ( !$state->is_installed ) {
		$log->info("Checking OpenBSD image...");
		my $image =
		    App::FuguVM::Miniroot->new( $self->_cache_dir, $proxy );
		$image_path = $image->ensure( $config->{version} );

		if ( !defined $image_path ) {
			my $url = $image->url( $config->{version} );
			$log->error(
"Failed to download image for OpenBSD $config->{version}"
			);
			$log->error("URL: $url");
			$log->error("Try downloading manually: curl -fLO $url");
			return EXIT_ERROR;
		}

		$log->info("Using cached image: $image_path");
	}

	# Make sure that the disk exists
	my $disk_path = $state->disk_path;

	if ( !$state->disk_exists ) {
		$log->info("Creating disk image ($config->{disk_size})...");
		my $disk = App::FuguVM::Disk->new( $state->state_dir );
		my $result =
		    $disk->create( $config->{name}, $config->{disk_size} );
		if ( !defined $result ) {
			$log->error("Failed to create disk");
			return EXIT_ERROR;
		}
	}

	# Start the VM
	$log->info("Starting VM...");

	# Attach the install media only when the system is not installed
	my $boot_image = $state->is_installed ? undef : $image_path;
	my $pid        = $self->_start_qemu($boot_image);
	if ( !defined $pid ) {
		$log->error("Failed to start VM");
		return EXIT_ERROR;
	}

	$log->info("Started $config->{name} (PID: $pid)");

	# Install the system if necessary
	if ( !$state->is_installed ) {

		# The proxy already runs. The code above started it for the
		# image download. Use the VM-accessible URL for the
		# installation. The VM connects to the host through the
		# gateway.
		my $install_proxy_url = $proxy_vm_url // 'none';

		# Generate a strong random password for this installation
		my $root_password = Fugu::Random->random_password(32);
		$state->set_root_password($root_password);
		$log->info("Generated secure root password");

		$log->info("Installing OpenBSD...");
		my $expect = App::FuguVM::Console->new(
			host => '127.0.0.1',
			port => $config->{console_port},
		);

		# Use the generated password for the installation
		my $install_config = {
			%$config,
			root_password => $root_password,
			proxy_url     => $install_proxy_url,
		};
		my $ok = $expect->run_install($install_config);
		if ( !$ok ) {
			$log->error("Installation failed");
			return EXIT_ERROR;
		}

		$state->mark_installed;
		$log->info("Installation complete");

		# Stop the VM gracefully through QMP. The image cache
		# captures the disk at exactly this point: installed,
		# pristine, and without the per-checkout SSH key. Thus the
		# capture must know that QEMU is really gone. It must not
		# assume it.
		$log->info("Stopping installation VM...");
		$self->_qmp_quit;
		my $clean_exit = $self->_wait_exit(30);

		if ( !$clean_exit ) {
			$log->warning(
"Installation VM did not exit on request, force stopping"
			);
			$self->_force_stop;
			$self->_wait_exit(10);
		}
		$state->clear_vm_pid;

		# Publish the installed disk as a cached base image. A VM
		# that was force stopped can leave the disk mid-write. Thus
		# the code skips that capture and does not publish it.
		if ( defined $cache_key ) {
			if ($clean_exit) {
				$self->_cache_store( $cache, $cache_key,
					$root_password );
			}
			else {
				$log->warning(
"Skipping image cache: installation VM was force stopped"
				);
			}
		}

		# Restart the VM without the install media
		$log->info("Restarting installed system...");
		$pid = $self->_start_qemu;    # No boot image, no exit_on_halt
		if ( !defined $pid ) {
			$log->error("Failed to restart VM");
			return EXIT_ERROR;
		}
		$log->info("Started $config->{name} (PID: $pid)");

		# Install the SSH authorized key for future key-based
		# authentication
		return $self->_complete_ssh_setup;
	}

	# The VM is installed. Check if the SSH key must be installed or
	# updated.
	if ( $self->_needs_ssh_key_update ) {

		# The SSH key is not installed, or it changed in the
		# configuration. Use password authentication to wait for
		# SSH. Then install the key.
		return $self->_complete_ssh_setup;
	}

	# Wait for SSH. An installed VM uses key-based authentication.
	$log->info("Waiting for SSH...");
	if ( !$self->wait_ssh(120) ) {
		$log->error("Timeout waiting for SSH");
		return EXIT_TIMEOUT;
	}

	$log->info("VM ready");
	return EXIT_SUCCESS;
}

# $self->_image_cache:
#	Return the installed-image cache for this VM's configured
#	cache_dir. Return undef when caching is off. 'up --no-cache'
#	turns caching off for a single invocation. 'image_cache no'
#	turns it off in the configuration. Both stop restore and save
#	together. A half-cached run would leave an overlay with a base
#	that nothing published.
sub _image_cache ($self)
{
	return if $self->{no_cache};

	my $enabled = $self->{config}{image_cache};
	return if defined $enabled && !$enabled;

	return App::FuguVM::DiskCache->new( $self->_cache_dir );
}

# $self->_verify_backing_chain:
#	Make sure that the backing image of the working disk, if the
#	disk has one, is present. Return true when the chain resolves.
#	On a break, log the missing file and a remedy, and return
#	false. Thus a pruned or evicted cache entry fails with an
#	explanation, not with an opaque QEMU open error at boot.
sub _verify_backing_chain ($self)
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	my $disk    = App::FuguVM::Disk->new( $state->state_dir );
	my $backing = $disk->backing_file( $config->{name} );
	return 1 if !defined $backing;
	return 1 if -f $backing;

	$log->error("Backing image missing: $backing");

	my $cache_dir = $self->_cache_dir;
	if ( index( $backing, "$cache_dir/" ) == 0 ) {
		$log->error(
"The image cache no longer holds this disk's base image."
		);
	}
	$log->error("Run 'fuguvm destroy' and 'fuguvm up' to rebuild the VM.");

	return 0;
}

# $self->_cache_restore($cache, $key):
#	Create the working disk as an overlay on a cached base image.
#	Seed the state that the installation would have written. Return
#	true on a cache hit. Return false on a miss or on any failure.
#	In both cases the caller then installs from scratch.
sub _cache_restore ( $self, $cache, $key )
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	my $hit = $cache->lookup($key);
	if ( !defined $hit ) {
		$log->info("No cached image for $key, installing");
		return 0;
	}

	my $disk = App::FuguVM::Disk->new( $state->state_dir );
	my $path =
	    $disk->create( $config->{name}, undef, $hit->{base} );
	if ( !defined $path ) {
		$log->warning(
			"Cannot overlay cached image $key, installing instead");
		return 0;
	}

	# The base was captured from an installed system. Thus the state
	# that the installer would have written comes from the metadata
	# of the base. The later SSH key install authenticates with the
	# root password. That password is baked into the image.
	$state->mark_installed;
	my $password = $hit->{meta}{root_password};
	$state->set_root_password($password) if defined $password;
	$state->data->{cached_from} = $key;
	$state->save;

	$log->info("Using cached image $key");
	return 1;
}

# $self->_cache_store($cache, $key, $root_password):
#	Publish the freshly installed disk as a cached base image. Then
#	replace the working disk with an overlay on that image. The
#	operation is best effort. On any failure it keeps the
#	standalone disk in place and warns. 'up' must never fail
#	because caching failed.
sub _cache_store ( $self, $cache, $key, $root_password )
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	$log->info("Caching installed image as $key...");

	my $base = $cache->store(
		$key,
		$state->disk_path,
		{
			root_password => $root_password,
			version       => $config->{version},
			disk_size     => $config->{disk_size},
		} );
	if ( !defined $base ) {
		$log->warning("Could not cache installed image, continuing");
		return 0;
	}

	if ( !$self->_reparent_disk($base) ) {
		$log->warning(
			"Cached image saved but disk left standalone: $base");
		return 0;
	}

	$log->info("Cached installed image: $base");
	return 1;
}

# $self->_reparent_disk($base):
#	Replace the working disk with a fresh overlay backed by $base.
#	The method moves the old disk aside and does not delete it.
#	Thus a failure to create the overlay cannot leave the VM
#	without a disk.
sub _reparent_disk ( $self, $base )
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	my $disk_path = $state->disk_path;
	my $saved     = "$disk_path.replaced";

	unlink $saved if -f $saved;
	rename $disk_path, $saved or do {
		$log->warning("Cannot move $disk_path aside: $!");
		return 0;
	};

	# Disk::create returns early on an existing path. Thus the
	# rename above is what makes this call create the overlay.
	my $disk = App::FuguVM::Disk->new( $state->state_dir );
	my $path = $disk->create( $config->{name}, undef, $base );
	if ( !defined $path ) {
		rename $saved, $disk_path
		    or $log->error("Cannot restore $disk_path: $!");
		return 0;
	}

	unlink $saved or $log->warning("Cannot remove $saved: $!");
	return 1;
}

sub down ($self)
{
	# Stop the proxy if it runs
	if ( $self->_stop_proxy ) {
		$self->{log}->info("Proxy stopped");
	}

	return $self->stop;
}

sub destroy ($self)
{
	my $state  = $self->{state};
	my $log    = $self->{log};
	my $config = $self->{config};

	# Stop the proxy if it runs
	if ( $self->_stop_proxy ) {
		$log->info("Proxy stopped");
	}

	# Stop the VM if it runs
	if ( $self->_is_running ) {
		$self->stop(1);
	}

	# Remove the disk
	my $disk_path = $state->disk_path;
	if ( -f $disk_path ) {
		$log->info("Removing disk image...");
		unlink $disk_path or do {
			$log->error("Cannot remove $disk_path: $!");
			return EXIT_ERROR;
		};
	}

	# Remove the QMP socket
	my $qmp_path = $self->_qmp_socket_path;
	unlink $qmp_path if -S $qmp_path;

	# Clear the state
	%{ $state->data } = ();
	$state->save;

	$log->info("VM '$config->{name}' destroyed");
	return EXIT_SUCCESS;
}

sub start ($self)
{
	my $state  = $self->{state};
	my $log    = $self->{log};
	my $config = $self->{config};

	if ( $self->_is_running ) {
		$log->error("VM '$config->{name}' is already running");
		return EXIT_VM_RUNNING;
	}

	if ( !$state->disk_exists ) {
		$log->error("No disk image. Run 'fuguvm up' first.");
		return EXIT_ERROR;
	}

	my $pid = $self->_start_qemu;
	if ( !defined $pid ) {
		$log->error("Failed to start VM");
		return EXIT_ERROR;
	}

	$log->info("Started $config->{name} (PID: $pid)");
	return EXIT_SUCCESS;
}

sub stop ( $self, $force = 0 )
{
	my $state  = $self->{state};
	my $log    = $self->{log};
	my $config = $self->{config};

	if ( !$self->_is_running ) {
		$log->info("VM '$config->{name}' is not running");
		return EXIT_SUCCESS;
	}

	if ($force) {
		$log->warning(
			"Force stopping VM (filesystem may be corrupted)");
		return $self->_stop_unclean;
	}

	# Try a graceful shutdown with a filesystem sync
	$log->info("Shutting down VM gracefully...");
	if ( $self->_graceful_shutdown ) {
		$state->mark_clean_shutdown;
		$state->clear_vm_pid;
		$log->info("VM stopped");
		return EXIT_SUCCESS;
	}

	# If the graceful shutdown times out, force stop the VM
	$log->warning(
"Graceful shutdown timed out, force stopping (risk of corruption)"
	);
	return $self->_stop_unclean;
}

# $self->_stop_unclean:
#	Force-stop the VM and record the unclean shutdown, so the next
#	'up' checks the disk.
sub _stop_unclean ($self)
{
	my $state = $self->{state};

	$state->mark_unclean_shutdown;
	$self->_force_stop;
	$state->clear_vm_pid;
	$self->{log}->info("VM stopped");

	return EXIT_SUCCESS;
}

sub status ($self)
{
	my $state  = $self->{state};
	my $config = $self->{config};

	my $running = $self->_is_running;
	my $pid     = $state->get_vm_pid;

	# Query the QEMU status through QMP if the VM runs
	my $qemu_status;
	if ($running) {
		my $qmp = $self->_qmp_connect;
		if ($qmp) {
			my $status = $qmp->query_status;
			$qemu_status = $status->{status} if $status;
			$qmp->disconnect;
		}
	}

	return {
		name  => $config->{name},
		state => $running ? ( $qemu_status // 'running' ) : 'stopped',
		pid   => $pid,
		ssh_port     => $config->{ssh_port},
		console_port => $config->{console_port},
		installed    => $state->is_installed ? 1 : 0,
		disk_exists  => $state->disk_exists  ? 1 : 0,
	};
}

sub is_running ($self)
{
	return $self->_is_running;
}

sub ssh_port ($self)
{
	return $self->{config}{ssh_port};
}

sub console_port ($self)
{
	return $self->{config}{console_port};
}

# $self->wait_ssh($timeout, $password):
#	Wait for SSH to become available. Without a password, the
#	connection uses the SSH agent for authentication. The initial
#	installation gives the root password, because the SSH key is
#	not in yet.
sub wait_ssh ( $self, $timeout = 120, $password = undef )
{
	my $ssh = Fugu::SSH->new(
		host => '127.0.0.1',
		port => $self->{config}{ssh_port},
		user => 'root',
		( defined $password ? ( password => $password ) : () ),
	);

	return $ssh->wait_available($timeout);
}

# $self->_needs_ssh_key_update:
#	Check if the SSH key must be installed or updated. Return true
#	if no key is installed. Also return true if the configured key
#	differs from the installed key.
sub _needs_ssh_key_update ($self)
{
	my $config = $self->{config};
	my $state  = $self->{state};

	my $configured_key = $config->{ssh_pubkey};
	my $installed_key  = $state->get_installed_ssh_pubkey;

	# No key is configured. There is nothing to install.
	return 0 if !defined $configured_key || $configured_key eq '';

	# No key is installed yet
	return 1 if !defined $installed_key;

	# Compare the keys. Normalize the whitespace for the comparison.
	my $configured_normalized = $configured_key =~ s/\s+/ /gr;
	my $installed_normalized  = $installed_key  =~ s/\s+/ /gr;

	return $configured_normalized ne $installed_normalized;
}

# $self->_complete_ssh_setup():
#	Install or update the SSH key on the VM. The method
#	authenticates with the stored root password. It runs to recover
#	from a failed first boot, or when the configured SSH key
#	changed.
sub _complete_ssh_setup ($self)
{
	my $state  = $self->{state};
	my $config = $self->{config};
	my $log    = $self->{log};

	my $root_password = $state->get_root_password;
	if ( !defined $root_password ) {
		$log->error(
			"No root password stored - cannot complete SSH setup");
		return EXIT_ERROR;
	}

	$log->info("Updating SSH key...");

	# Wait for SSH with password authentication
	$log->info("Waiting for SSH...");
	if ( !$self->wait_ssh( 120, $root_password ) ) {
		$log->error("Timeout waiting for SSH");
		return EXIT_TIMEOUT;
	}

	# Install the SSH authorized key
	if ( !$self->_install_ssh_key($root_password) ) {
		$log->error("Failed to install SSH key");
		return EXIT_ERROR;
	}
	$log->info("SSH key installed");

	$log->info("VM ready");
	return EXIT_SUCCESS;
}

# $self->_install_ssh_key($password):
#	Install the SSH public key from the configuration into
#	authorized_keys. The method uses password authentication,
#	because the key is not yet installed.
sub _install_ssh_key ( $self, $password )
{
	my $config = $self->{config};
	my $state  = $self->{state};
	my $log    = $self->{log};

	# Get the SSH public key from the configuration
	my $ssh_pubkey = $config->{ssh_pubkey};
	if ( !defined $ssh_pubkey || $ssh_pubkey eq '' ) {
		$log->error("No ssh_pubkey configured in ~/.fuguvmrc");
		return 0;
	}

	# Connect with the password
	my $ssh = Fugu::SSH->new(
		host     => '127.0.0.1',
		port     => $config->{ssh_port},
		user     => 'root',
		password => $password,
	);

	# Create the .ssh directory
	my $result =
	    $ssh->run_command('mkdir -p /root/.ssh && chmod 700 /root/.ssh');
	if ( $result->{exit_code} != 0 ) {
		return 0;
	}

	# Write the authorized_keys file
	my $authkeys_content = $ssh_pubkey . "\n";
	if (
		$ssh->write_file(
			'/root/.ssh/authorized_keys', $authkeys_content,
			0600
		) != 0
	    )
	{
		return 0;
	}

	# Store the installed pubkey for a future comparison
	$state->mark_ssh_key_installed($ssh_pubkey);
	return 1;
}

# Graceful shutdown with a filesystem sync: sync through SSH, then
# power off through the ACPI power button, and report the result.
sub _graceful_shutdown ($self)
{
	my $config = $self->{config};
	my $log    = $self->{log};

	# Do a best-effort filesystem sync over SSH before the code
	# pulls the power. The sync has a hard time bound. A wedged
	# guest must never stall the shutdown. Also, libssh2 does not
	# reliably obey its own timeout on the connect and handshake. A
	# failure or a timeout here is acceptable. The ACPI powerdown
	# below runs the orderly shutdown of the guest, which syncs. A
	# force stop is the ultimate fallback.
	$self->_bounded(
		Fugu::SSH::DEFAULT_TIMEOUT() + 5,
		sub {
			my $ssh = Fugu::SSH->new(
				host => '127.0.0.1',
				port => $config->{ssh_port},
				user => 'root',
			);
			return $ssh->run_command('sync; sync; sync');
		} );

	# Ask the guest to power off through the ACPI power button. Then
	# wait.
	if ( $self->_qmp_powerdown && $self->_wait_exit(60) ) {
		$log->info("Shutdown via ACPI powerdown");
		return 1;
	}

	return 0;
}

# $self->_bounded($seconds, $code):
#	Run $code under a hard wall-clock deadline, so a blocked guest
#	interaction cannot stall the caller. The guard itself is
#	Fugu::Timeout; this wrapper adds the log line.
sub _bounded ( $self, $seconds, $code )
{
	my $result = Fugu::Timeout::bounded( $seconds, $code );
	return $result if defined $result;

	$self->{log}->warning("Guest did not respond within ${seconds}s");
	return;
}

# $self->_ensure_proxy:
#	Start the caching proxy if it does not run, and return it. The
#	method returns undef when the proxy cannot start.
#
#	The lifecycle lives here and not in App::FuguVM::State, because a
#	state file must not start a process. That split is what removed
#	the require cycle between the two modules.
sub _ensure_proxy ($self)
{
	my $proxy = $self->_proxy;
	return $proxy if $proxy->is_running;

	unless ( defined $proxy->start ) {
		$self->{log}->warning(
			'Proxy did not start: %s',
			$proxy->error // 'unknown'
		);
		return;
	}

	return $proxy;
}

# $self->_stop_proxy:
#	Stop the proxy if it runs. The method returns 1 when it stopped
#	one, and 0 when there was none.
sub _stop_proxy ($self)
{
	my $proxy = $self->_proxy;
	return 0 unless $proxy->is_running;

	$proxy->stop;

	return 1;
}

# $self->_proxy:
#	Build the proxy supervisor over this VM's state.
sub _proxy ($self)
{
	my $state = $self->{state};

	return App::FuguVM::Proxy->new(
		cache   => App::FuguVM::Proxy::Cache->new( $self->_cache_dir ),
		pidfile => $state->proxy_pidfile,
		store   => $state->store,
		logfile => $state->vm_state_dir . '/proxy.log',
		log     => $self->{log},
	);
}

# $self->_force_stop:
#	Stop the QEMU process deterministically. Send SIGTERM first:
#	QEMU exits and flushes its disk caches. Escalate to SIGKILL if
#	the process stays. Unlike a QMP 'quit', this method cannot hang
#	on an unresponsive monitor socket. Thus it is a safe last
#	resort.
sub _force_stop ($self)
{
	my $pid = $self->{state}->get_vm_pid;
	return 1 if !defined $pid;
	return Fugu::Process->terminate( $pid, grace_period => 5 );
}

# QMP methods
sub _qmp_socket_path ($self)
{
	return $self->{state}{vm_state_dir} . '/qmp.sock';
}

sub _qmp_connect ($self)
{
	my $qmp = App::FuguVM::QMP->new( $self->_qmp_socket_path );
	return $qmp->open_connection ? $qmp : undef;
}

sub _qmp_powerdown ($self)
{
	my $qmp    = $self->_qmp_connect or return 0;
	my $result = $qmp->powerdown;
	$qmp->disconnect;
	return $result;
}

sub _qmp_quit ($self)
{
	my $qmp = $self->_qmp_connect or return 0;
	return $qmp->quit;
}

sub _is_running ($self)
{
	my $pid = $self->{state}->get_vm_pid;
	return 0 if !defined $pid;

	# A QEMU that became a zombie is not running. Fugu::Process
	# reaps it and says so; a bare kill(0) would call it alive.
	return Fugu::Process->is_alive($pid) ? 1 : 0;
}

# $self->_wait_exit($timeout):
#	Wait for the QEMU process to leave. The poll is sub-second, so
#	a VM that stops at once does not cost a whole second.
sub _wait_exit ( $self, $timeout )
{
	my $pid = $self->{state}->get_vm_pid;
	return 1 if !defined $pid;

	return Fugu::Process->wait_exit( $pid, $timeout );
}

# QEMU startup
sub _start_qemu ( $self, $boot_image = undef )
{
	my $config = $self->{config};
	my $state  = $self->{state};

	my @cmd = (QEMU_BINARY);

	# Set the machine type for arm64. Select the accelerator by the
	# host capability.
	push @cmd, '-M', 'virt,highmem=off';
	push @cmd, $self->_accel_args;

	# Memory and CPU
	push @cmd, '-m',   $config->{memory} // MEMORY_DEFAULT;
	push @cmd, '-smp', CPU_COUNT;

	# EFI firmware for arm64
	my $bios = $self->_find_efi_firmware;
	if ( defined $bios ) {
		push @cmd, '-bios', $bios;
	}

	# The main disk with the safe cache mode. The writethrough mode
	# syncs on each write.
	my $disk_path = $state->disk_path;
	push @cmd, '-drive',
	    "file=$disk_path,format=qcow2,if=virtio,cache=writethrough";

	# Boot image (CD-ROM) for installation
	if ( defined $boot_image ) {
		push @cmd, '-drive',
		    "file=$boot_image,format=raw,if=virtio,readonly=on";
	}

	# Network with port forwarding
	my $ssh_port = $config->{ssh_port};
	push @cmd, '-device', 'virtio-net-pci,netdev=net0';
	push @cmd, '-netdev', "user,id=net0,hostfwd=tcp::$ssh_port-:22";

	# Serial console on telnet
	my $console_port = $config->{console_port};
	push @cmd, '-serial', "tcp::$console_port,server,telnet,nowait";

	# QMP control socket
	my $qmp_path = $self->_qmp_socket_path;
	unlink $qmp_path if -S $qmp_path;
	push @cmd, '-qmp', "unix:$qmp_path,server,nowait";

	# PID file for reliable tracking
	push @cmd, '-pidfile', $state->vm_pidfile->path;

	# No graphics display (headless)
	push @cmd, '-display', 'none';

	# Use Fugu::Process to spawn QEMU
	my $log_file = $state->vm_state_dir . '/qemu.log';
	my $result   = Fugu::Process->spawn_command(
		cmd       => \@cmd,
		daemonize => 1,
		stdout    => $log_file,
		stderr    => $log_file,
	);

	return unless $result->{success};

	# Wait until QEMU writes the PID file
	my $pid = Fugu::Timeout::wait_until(
		5, 0.1,
		sub {
			my $qemu_pid = $state->get_vm_pid;
			return $qemu_pid
			    if defined $qemu_pid
			    && Fugu::Process->is_alive($qemu_pid);
			return;
		} );

	unless ( defined $pid ) {
		$self->_dump_qemu_log($log_file);
		return;
	}

	# Arm the crash detection: was_unclean_shutdown reports true
	# when the state says running and the process is gone.
	$state->mark_running;

	# Make sure that QEMU accepts console connections before the
	# installer tries to attach. A QEMU that exited at startup, for
	# example with a bad accelerator or missing firmware, leaves the
	# port closed. This check fails fast with the QEMU log, not with
	# a long telnet timeout later.
	if ( defined $boot_image
		&& !$self->_wait_console_ready( $config->{console_port}, 30 ) )
	{
		$self->{log}
		    ->error( 'QEMU console port %d not listening after start',
			$config->{console_port} );
		$self->_dump_qemu_log($log_file);
		return;
	}

	return $pid;
}

# $self->_wait_console_ready($port, $timeout):
#	Poll the console TCP port until it accepts a connection. Thus
#	the telnet of the installer attaches to a live console. QEMU
#	binds the port at startup, before the guest boots. Thus the
#	poll is quick when QEMU is healthy, and bounded when it is not.
sub _wait_console_ready ( $self, $port, $timeout )
{
	require IO::Socket::INET;

	my $ready = Fugu::Timeout::wait_until(
		$timeout, 0.2,
		sub {
			my $sock = IO::Socket::INET->new(
				PeerAddr => '127.0.0.1',
				PeerPort => $port,
				Proto    => 'tcp',
				Timeout  => 2,
			);
			if ( defined $sock ) {
				$sock->close;
				return 'ready';
			}

			# Stop the wait early if QEMU already exited
			my $qemu_pid = $self->{state}->get_vm_pid;
			return 'gone'
			    if defined $qemu_pid
			    && !Fugu::Process->is_alive($qemu_pid);

			return;
		} );

	return defined $ready && $ready eq 'ready' ? 1 : 0;
}

# $self->_dump_qemu_log($log_file):
#	Show the tail of the QEMU log. Thus a startup failure is
#	visible in the CI output, and shell access to the runner is not
#	necessary.
sub _dump_qemu_log ( $self, $log_file )
{
	open my $fh, '<', $log_file or return;
	my @lines = <$fh>;
	close $fh;

	@lines = splice( @lines, -40 ) if @lines > 40;
	$self->{log}->error('QEMU log tail:');
	$self->{log}->error( '  %s', $_ ) for map { chomp; $_ } @lines;

	return;
}

# $self->_accel_args():
#	Pick the QEMU accelerator for the host. Use HVF on macOS. Use
#	KVM on aarch64 Linux hosts with /dev/kvm. Use TCG software
#	emulation in the other cases, or when --emulate was given. Host
#	CPU passthrough is only valid with hardware acceleration. TCG
#	needs a named model.
sub _accel_args ($self)
{
	my $accel;
	if ( $self->{emulate} ) {
		$accel = 'tcg';
	}
	elsif ( $^O eq 'darwin' ) {
		$accel = 'hvf';
	}
	elsif ( $^O eq 'linux' && -w '/dev/kvm' && _host_arch() eq 'aarch64' ) {
		$accel = 'kvm';
	}
	else {
		$accel = 'tcg';
	}

	$self->{log}->debug("Using QEMU accelerator: $accel")
	    if $self->{log};

	return ( '-accel', $accel, '-cpu', $accel eq 'tcg' ? TCG_CPU : 'host' );
}

# _host_arch():
#	Return the host machine architecture from uname.
sub _host_arch ()
{
	require POSIX;
	my @uname = POSIX::uname();
	return $uname[4] // '';
}

sub _find_efi_firmware ($self)
{
	my @paths = (
		'/opt/homebrew/share/qemu/edk2-aarch64-code.fd',
		'/usr/local/share/qemu/edk2-aarch64-code.fd',
		'/usr/share/qemu-efi-aarch64/QEMU_EFI.fd',
		'/usr/share/AAVMF/AAVMF_CODE.fd',
		'/usr/share/qemu/edk2-aarch64-code.fd',
	);

	for my $path (@paths) {
		return $path if -f $path;
	}

	# Try a glob for the versioned Homebrew paths
	my @glob_paths =
	    glob('/opt/homebrew/Cellar/qemu/*/share/qemu/edk2-aarch64-code.fd');
	return $glob_paths[0] if @glob_paths;

	return;
}

# $self->_cache_dir:
#	Return the configured cache directory. App::FuguVM::Config::load_vm
#	injects it into the per-VM config. The fallback only serves VM
#	objects built without a configuration.
sub _cache_dir ($self)
{
	my $configured = $self->{config}{cache_dir};
	return $configured if defined $configured && $configured ne '';

	my $home = $ENV{HOME} // '/root';
	return "$home/.cache/fuguvm";
}

1;
