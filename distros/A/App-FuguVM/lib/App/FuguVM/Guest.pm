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
our $VERSION = '0.2.0';

use App::FuguVM::Arch;
use App::FuguVM::Autoinstall;
use App::FuguVM::Config;
use App::FuguVM::Miniroot;
use App::FuguVM::Mirror;
use App::FuguVM::DiskCache;
use App::FuguVM::Disk;
use App::FuguVM::Console;
use App::FuguVM::Proxy;
use App::FuguVM::QMP;
use App::FuguVM::State;

use Fcntl qw(:flock);
use Fugu::File;
use Fugu::Random;
use Fugu::Process;
use Fugu::SSH;
use Fugu::Timeout;

use constant {
	EXIT_SUCCESS       => 0,
	EXIT_ERROR         => 1,
	EXIT_CONFIG_ERROR  => 3,
	EXIT_VM_RUNNING    => 5,
	EXIT_TIMEOUT       => 7,
	EXIT_EXPECT_FAILED => 9,

	MEMORY_DEFAULT => '1G',
	CPU_COUNT      => 2,

	# The port lock closes the window between the probe and the
	# record of both ports. A probe is quick, so a long wait means
	# a wedged holder, and the probe then runs without the lock.
	PORT_LOCK_TIMEOUT => 30,

	# The bound on one 'qemu --version' run.
	QEMU_VERSION_TIMEOUT => 10,
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

	# The QEMU binary of the architecture must be on PATH before
	# any other work starts.
	return EXIT_CONFIG_ERROR if !$self->_require_qemu;

	return EXIT_ERROR if !$self->_check_installed_arch;

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

	# The version gate runs one time for each invocation, before
	# any expensive work starts.
	my $failure = $self->_check_qemu_version;
	return $failure if defined $failure;

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

	# The mode decides the origin of the disk. The configuration
	# loader derives the value, and no module compares the
	# directives again.
	my $mode = $config->{install_mode} // 'expect';

	# Derive the installed-image cache key one time only, before the
	# installer runs. key() hashes its script at call time. An
	# install takes tens of minutes. A key derived again after the
	# install would publish the image the OLD installer made under
	# the NEW digest.
	my $cache     = $self->_image_cache;
	my $cache_key = defined $cache ? $cache->key($config) : undef;

	# An imported base lives in the cache, so the import mode
	# cannot run without one. The configuration loader refuses
	# 'image_cache no'; this check covers 'up --no-cache'.
	if ( $mode eq 'import' && !defined $cache ) {
		$log->error(  "base_disk needs the image cache;"
			    . " run 'fuguvm up' without --no-cache" );
		return EXIT_CONFIG_ERROR;
	}
	if ( $mode eq 'import' && !defined $cache_key ) {
		$log->error("Cannot derive the cache key of the imported base");
		return EXIT_ERROR;
	}

	# Outside the expect mode the operator owns the credential.
	# Seed the state from root_password_file, so the SSH key setup
	# can authenticate. The state then behaves as after an expect
	# install.
	if ( $mode ne 'expect' && defined $config->{root_password_file} ) {
		my $password = $self->_root_password;
		$state->set_root_password($password) if defined $password;
	}

	# Restore from the installed-image cache when there is no disk
	# yet. A miss can mean that a sibling run installs this entry
	# right now. The lock makes this run wait, and the second lookup
	# then uses the entry that the sibling published. A run without
	# the lock still installs correctly, because store() is
	# write-once: it wastes an install, never the cache.
	my $cache_lock;
	if ( !$state->disk_exists && defined $cache_key ) {
		if ( !$self->_cache_restore( $cache, $cache_key ) ) {

			# The wait can last as long as one installation,
			# so the operator hears about it first.
			$log->info("Taking the image-cache lock of $cache_key");
			$cache_lock = $cache->lock_entry($cache_key);
			if ( !defined $cache_lock ) {
				$log->warning(
"Image-cache lock not acquired, installing without it"
				);
			}
			elsif ( $self->_cache_restore( $cache, $cache_key ) ) {

				# The entry exists now, so nothing here
				# installs. Release the lock at once: a
				# sibling behind it needs only the entry.
				close $cache_lock;
				undef $cache_lock;
			}

			# The import mode installs nothing: publish the
			# outside file as the entry, then overlay it. The
			# lock above serializes the publication, so a
			# parallel fleet publishes one time.
			if ( !$state->disk_exists && $mode eq 'import' ) {
				my $imported =
				    $self->_import_base( $cache, $cache_key )
				    && $self->_cache_restore( $cache,
					$cache_key );
				if ( defined $cache_lock ) {
					close $cache_lock;
					undef $cache_lock;
				}
				return EXIT_ERROR if !$imported;
			}
		}
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
		my $mirror = $self->_mirror($proxy);
		my $image  = App::FuguVM::Miniroot->new( $self->_cache_dir,
			$proxy, $mirror );
		$image_path = $image->ensure;

		if ( !defined $image_path ) {
			my $url = $image->url;
			$log->error(
"Failed to get a verified image for OpenBSD $config->{version}"
			);
			$log->error( $mirror->error ) if defined $mirror->error;
			$log->error("URL: $url");
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

	# Resolve and record the ports directly before the spawn. An
	# 'up' that failed above then reserves no port for a guest
	# that never started.
	$failure = $self->_resolve_ports;
	return $failure if defined $failure;

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

		# The tool owns the credential in the expect mode only.
		# In the autoinstall mode the response file owns it, and
		# the seeding above stored the operator's copy.
		my $root_password;
		if ( $mode eq 'expect' ) {
			$root_password = $self->_root_password;
			$state->set_root_password($root_password);
		}
		else {
			$root_password = $state->get_root_password;
		}

		$log->info("Installing OpenBSD...");
		my $expect = App::FuguVM::Console->new(
			host => $self->connect_address,
			port => $self->console_port,
		);

		if ( $mode eq 'autoinstall' ) {
			my $failure =
			    $self->_run_autoinstall( $expect, $proxy_vm_url );
			return $failure if defined $failure;
		}
		else {
			# Use the generated password for the installation
			my $ok = $expect->run_install(
				$self->_install_config(
					$root_password, $install_proxy_url
				) );
			if ( !$ok ) {
				$log->error("Installation failed");
				return EXIT_EXPECT_FAILED;
			}
		}

		$state->mark_installed( $config->{arch} );
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

		# The runtime record stays: the restart below uses the
		# same ports, and a sibling that resolves ports in this
		# window must still skip them.

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

		# The entry is published, or this run cannot publish it.
		# Either way a waiting sibling can proceed now.
		if ( defined $cache_lock ) {
			close $cache_lock;
			undef $cache_lock;
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
		# authentication. Outside the expect mode a guest can
		# carry no configured key: the image must trust the key
		# of the operator already, and the wait below proves it.
		if ( $mode eq 'expect' || $self->_needs_ssh_key_update ) {
			return $self->_complete_ssh_setup;
		}
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
	$state->mark_installed( $config->{arch} );
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

# $self->_import_base($cache, $key):
#	Publish the configured base_disk as the cache entry of $key.
#	The publication costs one conversion of the whole image, and
#	it happens one time for each host: the entry is write-once,
#	and every guest of the project derives the same key. The tool
#	only reads the source file. The metadata holds no root
#	password, because the tool must not invent a credential for an
#	image that it did not install. Return 1 on success.
sub _import_base ( $self, $cache, $key )
{
	my $config = $self->{config};
	my $log    = $self->{log};
	my $source = $config->{base_disk};

	if ( !-f $source ) {
		$log->error(  "The base_disk file is gone: $source"
			    . " (cache miss for $key)" );
		return 0;
	}

	$log->info("Publishing $source as $key...");
	my $base = $cache->store(
		$key, $source,
		{
			imported_from => $source,
			install_mode  => 'import',
			version       => $config->{version},
		} );
	if ( !defined $base ) {

		# store is write-once, so a sibling can have published
		# the entry inside the window. A lookup decides.
		return defined $cache->lookup($key) ? 1 : 0;
	}

	$log->info("Published imported base: $base");
	return 1;
}

# $self->_install_config($root_password, $proxy_url):
#	Return the configuration of one expect install. The verify
#	flag rides along as the word that the script reads: 'yes' or
#	'no'.
sub _install_config ( $self, $root_password, $proxy_url )
{
	return {
		%{ $self->{config} },
		root_password => $root_password,
		proxy_url     => $proxy_url // 'none',
		verify => ( $self->{config}{verify} // 1 ) ? 'yes' : 'no',
	};
}

# $self->_mirror($proxy):
#	Build the mirror of this guest over the cache of the proxy. A
#	run without a proxy still verifies: the mirror then builds a
#	cache over the same directory.
sub _mirror ( $self, $proxy = undef )
{
	my $config = $self->{config};

	my $cache =
	    defined $proxy
	    ? $proxy->cache
	    : App::FuguVM::Proxy::Cache->new( $self->_cache_dir );

	return App::FuguVM::Mirror->new(
		cache   => $cache,
		version => $config->{version},
		arch    => $config->{arch},
		verify  => $config->{verify} // 1,
		(
			defined $config->{signify_dir}
			? ( keys_dir => $config->{signify_dir} )
			: ()
		),
	);
}

# $self->_run_autoinstall($expect, $proxy_url):
#	Start the responder, drive the autoinstall over the console,
#	and stop the responder on every path out of the install.
#	Return undef on success, and an exit code on failure.
sub _run_autoinstall ( $self, $expect, $proxy_url = undef )
{
	my $log = $self->{log};

	my $responder = $self->_autoinstall($proxy_url);
	if ( !defined $responder->start ) {
		$log->error( 'Responder did not start: '
			    . ( $responder->error // 'unknown' ) );
		return EXIT_ERROR;
	}

	my $url = $responder->guest_url;
	$log->info("Responder started: $url");

	my $ok = $expect->run_autoinstall(
		{ %{ $self->{config} }, autoinstall_url => $url } );

	$responder->stop;

	if ( !$ok ) {
		$log->error("Autoinstall failed");
		return EXIT_EXPECT_FAILED;
	}

	return;
}

# $self->_root_password:
#	Return the root password of this guest. The tool owns the
#	credential in the expect mode, so the method generates one
#	there. In every other mode the operator owns it, and the
#	method returns the first line of root_password_file, with no
#	trailing newline, or undef without the directive. Thus the
#	secret has a short life in the process, and no configuration
#	hash carries it.
sub _root_password ($self)
{
	my $config = $self->{config};
	my $mode   = $config->{install_mode} // 'expect';

	if ( $mode eq 'expect' ) {
		$self->{log}->info("Generated secure root password");
		return Fugu::Random->random_password(32);
	}

	my $file = $config->{root_password_file};
	return if !defined $file;

	my $bits = ( stat $file )[2];
	$self->{log}->warning("The group or other users can read $file")
	    if defined $bits && $bits & 0044;

	open my $fh, '<', $file or do {
		$self->{log}->error("Cannot read $file: $!");
		return;
	};
	my $line = <$fh>;
	close $fh;
	return if !defined $line;

	chomp $line;
	return $line;
}

sub down ($self)
{
	# Stop the responder and the proxy if they run
	if ( $self->_stop_autoinstall ) {
		$self->{log}->info("Autoinstall responder stopped");
	}
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

	# Stop the responder and the proxy if they run
	if ( $self->_stop_autoinstall ) {
		$log->info("Autoinstall responder stopped");
	}
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

	return EXIT_CONFIG_ERROR if !$self->_require_qemu;

	return EXIT_ERROR if !$self->_check_installed_arch;

	if ( $self->_is_running ) {
		$log->error("VM '$config->{name}' is already running");
		return EXIT_VM_RUNNING;
	}

	if ( !$state->disk_exists ) {
		$log->error("No disk image. Run 'fuguvm up' first.");
		return EXIT_ERROR;
	}

	# The version gate and the port resolution run one time for
	# each invocation, before the spawn.
	my $failure = $self->_check_qemu_version;
	return $failure if defined $failure;

	$failure = $self->_resolve_ports;
	return $failure if defined $failure;

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

		# A crashed guest cannot clear its own record and its
		# own pid file, so the stop verb clears both here.
		$state->clear_vm_pid;
		$state->clear_runtime;
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
		$state->clear_runtime;
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
	$state->clear_runtime;
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

		# A dead process ID is not a fact of a stopped guest, so
		# a pid file that a crash left behind reads as empty.
		pid          => $running ? $pid : undef,
		arch         => $config->{arch},
		accel        => $self->accel,
		bind_address => $self->bind_address,
		ssh_port     => $self->ssh_port,
		console_port => $self->console_port,
		installed    => $state->is_installed ? 1 : 0,
		disk_exists  => $state->disk_exists  ? 1 : 0,

		# The proxy URL as the guest reaches it, or empty while
		# the proxy does not run. The port changes between runs,
		# so a consumer reads the value here and must not write
		# it in a file. Scalar context: a bare return would
		# collapse the pair.
		proxy_url => scalar $self->_proxy->guest_url,
	};
}

sub is_running ($self)
{
	return $self->_is_running;
}

# $self->accel:
#	Return the recorded accelerator while the guest runs: a guest
#	that started under --emulate runs TCG whatever the host can do
#	now. Return the accelerator that the tool selects now in every
#	other case. App::FuguVM::Arch->accelerator owns the choice.
sub accel ($self)
{
	if ( $self->{state} && $self->_is_running ) {
		my $recorded = $self->{state}->get_runtime->{accel};
		return $recorded if defined $recorded;
	}

	return 'tcg' if $self->{emulate};

	return $self->_arch->accelerator( $^O, _host_arch(),
		-w '/dev/kvm' ? 1 : 0 );
}

# $self->bind_address:
#	Return the host address of the forwarded ports. The
#	configuration loader injects the value; the fallback only
#	serves VM objects built without a configuration.
sub bind_address ($self)
{
	return $self->{config}{bind_address}
	    // App::FuguVM::Config::DEFAULT_BIND_ADDRESS();
}

# $self->connect_address:
#	Return the address that the tool connects to. A bind address
#	of 0.0.0.0 is not a destination, so the loopback address
#	serves that one case.
sub connect_address ($self)
{
	my $address = $self->bind_address;
	return '127.0.0.1' if $address eq '0.0.0.0';

	return $address;
}

# The resolved ports. Each method returns the recorded port, and
# falls back to the configured number. It returns undef for 'auto'
# with no record: the record dies with the run, so a stopped guest
# has no port.
sub ssh_port ($self)
{
	return $self->_resolved_port('ssh_port');
}

sub console_port ($self)
{
	return $self->_resolved_port('console_port');
}

sub _resolved_port ( $self, $directive )
{
	# The record describes the current run, so it serves only
	# while the guest runs. A crashed guest leaves a record
	# behind. That record must not read as a live port.
	if ( $self->{state} && $self->_is_running ) {
		my $recorded = $self->{state}->get_runtime->{$directive};
		return $recorded if defined $recorded;
	}

	# The answer is one scalar, undef included: a caller builds a
	# hash with it, and a bare return would collapse the pair.
	my $configured = $self->{config}{$directive};
	$configured = undef
	    if defined $configured
	    && $configured eq App::FuguVM::Config::AUTO_PORT();

	return $configured;
}

# $self->wait_ssh($timeout, $password):
#	Wait for SSH to become available. Without a password, the
#	connection uses the SSH agent for authentication. The initial
#	installation gives the root password, because the SSH key is
#	not in yet.
sub wait_ssh ( $self, $timeout = 120, $password = undef )
{
	my $ssh = Fugu::SSH->new(
		host => $self->connect_address,
		port => $self->ssh_port,
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
		host     => $self->connect_address,
		port     => $self->ssh_port,
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
	my $log = $self->{log};

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
				host => $self->connect_address,
				port => $self->ssh_port,
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

	# The spawn passes a fixed argument list, so the distfile cap
	# reaches the child through the environment.
	$ENV{FUGUVM_DISTFILE_LIMIT} = $self->{config}{distfile_cache} // 0;

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
		cache => App::FuguVM::Proxy::Cache->new(
			$self->_cache_dir, $self->{config}{distfile_cache} // 0
		),
		pidfile => $state->proxy_pidfile,
		store   => $state->store,
		logfile => $state->vm_state_dir . '/proxy.log',
		log     => $self->{log},
	);
}

# $self->_autoinstall($proxy_url):
#	Build the responder supervisor over this VM's state and the
#	guest URL of the mirror proxy.
sub _autoinstall ( $self, $proxy_url = undef )
{
	my $state = $self->{state};

	return App::FuguVM::Autoinstall->new(
		file      => $self->{config}{autoinstall},
		pidfile   => $state->autoinstall_pidfile,
		store     => $state->store,
		proxy_url => $proxy_url,
		logfile   => $state->vm_state_dir . '/autoinstall.log',
		log       => $self->{log},
	);
}

# $self->_stop_autoinstall:
#	Stop the responder if it runs. The method returns 1 when it
#	stopped one, and 0 when there was none. It follows _stop_proxy.
sub _stop_autoinstall ($self)
{
	my $responder = $self->_autoinstall;
	return 0 unless $responder->is_running;

	$responder->stop;

	return 1;
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
	my $arch   = $self->_arch;

	my @cmd = ( $arch->qemu_binary );

	# Set the machine type of the architecture. Select the
	# accelerator by the host capability.
	push @cmd, '-M', $arch->machine;
	push @cmd, $self->_accel_args;

	# Memory and CPU
	push @cmd, '-m',   $config->{memory} // MEMORY_DEFAULT;
	push @cmd, '-smp', CPU_COUNT;

	# EFI firmware of the architecture. Both machines boot through
	# EFI, so a start without a firmware file cannot work. Fail
	# with a message rather than boot into the wrong firmware.
	my $firmware = $self->_find_efi_firmware;
	if ( !defined $firmware ) {
		$self->{log}->error(
			sprintf( "No EFI firmware for %s guests found",
				$self->_arch->name ) );
		return;
	}
	my @args = $self->_firmware_args($firmware);
	return unless @args;
	push @cmd, @args;

	# The main disk with the safe cache mode. The writethrough mode
	# syncs on each write.
	my $disk_path = $state->disk_path;
	push @cmd, '-drive',
	    "file=$disk_path,format=qcow2,if=virtio,cache=writethrough";

	# Boot image (CD-ROM) for installation
	push @cmd, $self->_media_args($boot_image);

	# Network with port forwarding, and the serial console on
	# telnet
	my $console_port = $state->get_runtime->{console_port};
	push @cmd, $self->_network_args;
	push @cmd, $self->_serial_args;

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
		&& !$self->_wait_console_ready( $console_port, 30 ) )
	{
		$self->{log}
		    ->error( 'QEMU console port %d not listening after start',
			$console_port );
		$self->_dump_qemu_log($log_file);
		return;
	}

	return $pid;
}

# $self->_media_args($boot_image):
#	Return the QEMU arguments of the install media, or an empty
#	list when no media is attached. An autoinstall reboots
#	itself, and the miniroot is still attached. -no-reboot makes
#	the reboot an exit, so the guest cannot install a second
#	time.
sub _media_args ( $self, $boot_image = undef )
{
	return () if !defined $boot_image;

	my @args =
	    ( '-drive', "file=$boot_image,format=raw,if=virtio,readonly=on" );
	push @args, '-no-reboot'
	    if ( $self->{config}{install_mode} // '' ) eq 'autoinstall';

	return @args;
}

# $self->_network_args:
#	Return the QEMU network arguments. The ports come from the
#	record that _resolve_ports wrote before the spawn: the public
#	accessors serve a running guest only, and QEMU does not run
#	yet. The forwarded port binds to the configured host address,
#	and the default is loopback.
sub _network_args ($self)
{
	my $bind_address = $self->bind_address;
	my $ssh_port     = $self->{state}->get_runtime->{ssh_port};

	return ( '-device', 'virtio-net-pci,netdev=net0', '-netdev',
		"user,id=net0,hostfwd=tcp:$bind_address:" . "$ssh_port-:22",
	);
}

# $self->_serial_args:
#	Return the QEMU serial-console arguments: a telnet listener on
#	the bind address and the recorded console port.
sub _serial_args ($self)
{
	my $bind_address = $self->bind_address;
	my $console_port = $self->{state}->get_runtime->{console_port};

	return ( '-serial',
		"tcp:$bind_address:$console_port,server,telnet,nowait" );
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
				PeerAddr => $self->connect_address,
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
#	Return the accelerator arguments, with the matching CPU model.
#	Host CPU passthrough is only valid with hardware acceleration.
#	TCG needs the named model of the architecture. The choice
#	itself comes from accel.
sub _accel_args ($self)
{
	my $arch  = $self->_arch;
	my $accel = $self->accel;

	$self->{log}->debug("Using QEMU accelerator: $accel")
	    if $self->{log};

	return ( '-accel', $accel,
		'-cpu', $accel eq 'tcg' ? $arch->tcg_cpu : 'host' );
}

# $self->_arch:
#	Return the App::FuguVM::Arch object of the configured value,
#	and cache it. The configuration loader is the boundary of the
#	directive, so an unknown value here is a programming error.
sub _arch ($self)
{
	my $name = $self->{config}{arch};

	$self->{arch} //= App::FuguVM::Arch->new($name)
	    // die 'unknown architecture: ' . ( $name // '(none)' ) . "\n";

	return $self->{arch};
}

# $self->_qemu_path:
#	Return the path of the QEMU binary of the architecture on
#	PATH, or undef.
sub _qemu_path ($self)
{
	my $binary = $self->_arch->qemu_binary;

	for my $dir ( split /:/, $ENV{PATH} // '' ) {
		next if $dir eq '';
		my $path = "$dir/$binary";
		return $path if -f $path && -x $path;
	}

	return;
}

# $self->_require_qemu:
#	Diagnose an absent QEMU binary, once for up and start. The
#	message names the binary and the architecture.
sub _require_qemu ($self)
{
	return 1 if defined $self->_qemu_path;

	my $arch = $self->_arch;
	$self->{log}->error(
		sprintf(
			"QEMU binary '%s' for %s guests is not on PATH",
			$arch->qemu_binary, $arch->name
		) );

	return 0;
}

# $self->_check_qemu_version:
#	Enforce the optional qemu_version directive, once for up and
#	start. Return undef when the check passes, and when no
#	directive exists. Return EXIT_CONFIG_ERROR otherwise. A pinned
#	version that the tool cannot verify fails closed: an absent
#	binary, and output with no version in it, both refuse the
#	start. The match runs component by component, over the
#	components that the directive names: 9.0 accepts 9.0.4 and
#	refuses 9.1.0.
sub _check_qemu_version ($self)
{
	my $pinned = $self->{config}{qemu_version};
	return if !defined $pinned;

	my $reported = $self->_qemu_version;
	if ( !defined $reported ) {
		$self->{log}->error(
"Cannot read the QEMU version to check against the pinned $pinned"
		);
		return EXIT_CONFIG_ERROR;
	}

	my @want = split /\./, $pinned;
	my @have = split /\./, $reported;
	for my $i ( 0 .. $#want ) {
		next if defined $have[$i] && $have[$i] == $want[$i];

		$self->{log}->error(
"QEMU version $reported does not match the pinned $pinned"
		);
		return EXIT_CONFIG_ERROR;
	}

	return;
}

# $self->_qemu_version:
#	Return the version that the QEMU binary reports, or undef. The
#	version is the first dotted-decimal token of the first output
#	line.
sub _qemu_version ($self)
{
	my $binary = $self->_qemu_path;
	return if !defined $binary;

	my $result = Fugu::Process->run(
		cmd     => [ $binary, '--version' ],
		timeout => QEMU_VERSION_TIMEOUT,
	);
	return if !$result->{success};

	my ($line) = split /\n/, $result->{stdout} // '';
	return if !defined $line;

	my ($version) = $line =~ /([0-9]+(?:\.[0-9]+)+)/;

	return $version;
}

# $self->_resolve_ports:
#	Resolve both host ports, and record them with the selected
#	accelerator, before the tool spawns QEMU. A number resolves to
#	itself, and 'auto' takes a free port of the fixed range of its
#	directive. Return undef on success, and EXIT_ERROR when a range
#	is exhausted.
#
#	The port lock closes the window between the probe and the
#	record. One window stays open: a foreign process can take a
#	probed port before QEMU binds it. QEMU then fails to start, and
#	the tool reports that failure with the QEMU log.
sub _resolve_ports ($self)
{
	my $config = $self->{config};

	my %range = (
		ssh_port     => App::FuguVM::Config::DEFAULT_SSH_PORT(),
		console_port => App::FuguVM::Config::DEFAULT_CONSOLE_PORT(),
	);

	my $lock  = $self->_lock_ports;
	my $taken = $self->_taken_ports;

	# The fixed ports of every VM declaration of the project are
	# taken too, whether the declared guest runs now or not. The
	# loader injects the set, like cache_dir.
	%$taken = ( %$taken, %{ $config->{declared_ports} // {} } );

	# The fixed ports of this guest are taken too: a probe for one
	# directive must not select the number that the other directive
	# holds.
	for my $directive (qw(ssh_port console_port)) {
		my $configured = $config->{$directive};
		$taken->{$configured} = 1
		    if defined $configured
		    && $configured ne App::FuguVM::Config::AUTO_PORT();
	}

	my %resolved;
	for my $directive (qw(ssh_port console_port)) {
		my $configured = $config->{$directive};

		if ( defined $configured
			&& $configured eq App::FuguVM::Config::AUTO_PORT() )
		{
			my $first = $range{$directive};
			my $last =
			    $first + App::FuguVM::Config::AUTO_PORT_COUNT() - 1;

			my $port = $self->_free_port( $first, $last, $taken );
			if ( !defined $port ) {
				$self->{log}->error(
"No free $directive in the range $first-$last"
				);
				close $lock if defined $lock;
				return EXIT_ERROR;
			}
			$resolved{$directive} = $port;
		}
		else {
			$resolved{$directive} = $configured;
		}

		$taken->{ $resolved{$directive} } = 1
		    if defined $resolved{$directive};
	}

	$self->{state}->set_runtime( accel => $self->accel, %resolved );
	close $lock if defined $lock;

	return;
}

# $self->_free_port($first, $last, $taken):
#	Return the first port of the range that binds on the bind
#	address and that $taken does not hold. Return undef for an
#	exhausted range.
sub _free_port ( $self, $first, $last, $taken )
{
	require IO::Socket::INET;

	for my $port ( $first .. $last ) {
		next if $taken->{$port};

		my $sock = IO::Socket::INET->new(
			LocalAddr => $self->bind_address,
			LocalPort => $port,
			Proto     => 'tcp',
			Listen    => 1,
		);
		next if !defined $sock;

		$sock->close;
		return $port;
	}

	return;
}

# $self->_taken_ports:
#	Return the recorded ports of every guest of the project, as a
#	hash reference keyed by port. The method enumerates the state
#	directory, like App::FuguVM::CLI::_disks_backed_by: a record
#	counts whether a 'vm' block still declares its guest or not.
sub _taken_ports ($self)
{
	my %taken;

	my $state_dir = $self->{state}->state_dir;
	return \%taken if !-d $state_dir;

	opendir my $dh, $state_dir or return \%taken;
	my @names = sort grep { !/^\./ && -d "$state_dir/$_" } readdir $dh;
	closedir $dh;

	for my $name (@names) {
		my $sibling = App::FuguVM::State->new( $state_dir, $name )
		    or next;
		my $runtime = $sibling->get_runtime;
		for my $directive (qw(ssh_port console_port)) {
			my $port = $runtime->{$directive};
			$taken{$port} = 1 if defined $port;
		}
	}

	return \%taken;
}

# $self->_lock_ports:
#	Return the locked handle of ports.lock, or undef on the
#	deadline. The lock file lives in the cache directory, so every
#	project that shares that directory probes one port at a time.
#	The record exclusion of _taken_ports covers this project only.
#	A collision with an other project surfaces when QEMU binds the
#	port, as a reported startup failure. The caller probes without
#	the lock when the deadline elapses: a wedged holder must not
#	fail a run.
sub _lock_ports ($self)
{
	my $dir = $self->_cache_dir;
	Fugu::File->ensure_dir($dir) or return;

	my $path = "$dir/ports.lock";
	open my $fh, '>>', $path or do {
		$self->{log}->warning("Cannot open $path: $!");
		return;
	};

	my $locked = Fugu::Timeout::bounded( PORT_LOCK_TIMEOUT,
		sub { flock $fh, LOCK_EX } );
	return $fh if $locked;

	close $fh;
	$self->{log}->warning("Port lock not acquired, probing without it");

	return;
}

# $self->_check_installed_arch:
#	Report if the configured architecture matches the installed
#	disk, once for up and start. A disk belongs to one
#	architecture, so a changed directive must not start the wrong
#	QEMU on an existing disk. An absent record cannot prove a
#	difference, so the check passes.
sub _check_installed_arch ($self)
{
	my $config = $self->{config};

	my $installed = $self->{state}->get_installed_arch;
	return 1 if !defined $installed || $installed eq $config->{arch};

	$self->{log}->error(
"The disk of '$config->{name}' holds an $installed installation, not $config->{arch}"
	);
	$self->{log}->error("Run 'fuguvm destroy' to rebuild the VM.");

	return 0;
}

# _host_arch():
#	Return the host machine architecture from uname.
sub _host_arch ()
{
	require POSIX;
	my @uname = POSIX::uname();
	return $uname[4] // '';
}

# $self->_find_efi_firmware:
#	Return the firmware of the architecture as { code, vars }, or
#	undef. The vars entry is the variable-store template beside
#	the code file. It is undef when -bios boots the code file
#	alone. A code file without its template is not usable, so the
#	search walks on.
sub _find_efi_firmware ($self)
{
	my $arch = $self->_arch;

	my @candidates = $arch->firmware_paths;
	push @candidates, glob( $arch->firmware_glob );

	for my $code (@candidates) {
		next unless -f $code;

		my $vars = $arch->firmware_vars_path($code);
		next if defined $vars && !-f $vars;

		return { code => $code, vars => $vars };
	}

	return;
}

# $self->_firmware_args($firmware):
#	Return the QEMU arguments for the firmware, or an empty list
#	on failure. A code file without a variable store boots with
#	-bios. A code file with one boots through two pflash devices:
#	the code read-only, and a fresh copy of the variable-store
#	template. The copy is throwaway state, so every start makes it
#	again.
sub _firmware_args ( $self, $firmware )
{
	my $code = $firmware->{code};
	my $vars = $firmware->{vars};

	return ( '-bios', $code ) if !defined $vars;

	my $copy = $self->{state}->vm_state_dir . '/efivars.fd';
	require File::Copy;
	unless ( File::Copy::copy( $vars, $copy ) ) {
		$self->{log}->error("Cannot copy $vars to $copy: $!");
		return;
	}

	return (
		'-drive', "if=pflash,format=raw,readonly=on,file=$code",
		'-drive', "if=pflash,format=raw,file=$copy",
	);
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
