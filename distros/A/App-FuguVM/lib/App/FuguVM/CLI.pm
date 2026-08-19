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

package App::FuguVM::CLI;
our $VERSION = '0.1.1';

use Fugu::CLI;
use Fugu::File;
use Fugu::Log;
use Fugu::SSH;
use App::FuguVM::Config;
use App::FuguVM::Disk;
use App::FuguVM::Console;
use App::FuguVM::DiskCache;
use App::FuguVM::Proxy;
use App::FuguVM::State;
use App::FuguVM::Guest;

# The generic exit codes come from Fugu::CLI. Only the codes that
# mean something to a VM are defined here, and App::FuguVM::Guest uses them
# from here rather than defining the same numbers again.
use constant {
	EXIT_SUCCESS      => Fugu::CLI::EXIT_SUCCESS,
	EXIT_ERROR        => Fugu::CLI::EXIT_ERROR,
	EXIT_INVALID_ARGS => Fugu::CLI::EXIT_INVALID_ARGS,
	EXIT_CONFIG_ERROR => Fugu::CLI::EXIT_CONFIG_ERROR,
	EXIT_TIMEOUT      => Fugu::CLI::EXIT_TIMEOUT,

	EXIT_VM_NOT_FOUND  => 4,
	EXIT_VM_RUNNING    => 5,
	EXIT_EXPECT_FAILED => 9,

	# Scriptable: a script that runs
	# 'snapshot restore || provision-from-scratch' can tell a
	# missing layer from a real failure.
	EXIT_SNAPSHOT_NOT_FOUND => 11,
};

# The subcommands. Each entry names the method that runs it, whether
# it needs a loaded project, and its own options. Fugu::CLI parses
# and dispatches; nothing here repeats a Getopt::Long block. A method
# without the cmd_ prefix is an App::FuguVM::Guest lifecycle verb, and
# run() loads the VM and calls it directly.
my %COMMANDS = (
	up => {
		summary => 'Ensure VM is running (download, create, start)',
		usage   => '[--no-cache]',
		options => { 'no-cache' => 'ignore the installed-image cache' },
		method  => 'up',
	},
	down => {
		summary => 'Stop VM gracefully',
		method  => 'down',
	},
	destroy => {
		summary => 'Stop VM and delete disk image',
		method  => 'destroy',
	},
	status => {
		summary => 'Show VM status',
		method  => 'cmd_status',
	},
	start => {
		summary => 'Start VM in background',
		method  => 'start',
	},
	stop => {
		summary => 'Stop VM',
		usage   => '[--force]',
		options => { 'force|f' => 'kill the VM instead of asking it' },
		method  => 'stop',
	},
	ssh => {
		summary => 'Open SSH session or run command',
		usage   => '[command]',
		method  => 'cmd_ssh',
	},
	console => {
		summary => 'Show console connection info',
		method  => 'cmd_console',
	},
	expect => {
		summary => 'Run expect script against console',
		usage   => '<script> [args...]',
		method  => 'cmd_expect',
	},
	wait => {
		summary => 'Wait for VM to be ready (SSH available)',
		usage   => '[--timeout=N]',
		options => { 'timeout=s' => 'seconds to wait' },
		method  => 'cmd_wait',
	},
	cache => {
		summary => 'Manage installed images (list, clear [--stale])',
		usage   => '<list|clear> [--stale]',
		options => { 'stale' => 'keep the entry the current VM uses' },
		method  => 'cmd_cache',
	},
	snapshot => {
		summary => 'Manage snapshots (save, restore, rm, list)',
		usage   => '<save|restore|rm|list> [name] [--names]',
		options => { 'names' => 'print names only' },
		method  => 'cmd_snapshot',
	},
	disk => {
		summary => 'Manage disk (check, repair, info)',
		usage   => '<check|repair|info>',
		method  => 'cmd_disk',
	},
	init => {
		summary => 'Initialize .fuguvm/ directory',
		usage   => '[dir]',
		method  => 'cmd_init',
		offline => 1,
	},
);

sub new ( $class, %opts )
{
	my $mode =
	    $opts{quiet} ? Fugu::Log::MODE_QUIET : Fugu::Log::MODE_STDERR;
	my $log = Fugu::Log->new(
		mode  => $mode,
		level => 'info',
		ident => 'fuguvm',
	);

	my $self = bless {
		vm_name => $opts{vm} // 'default',
		project => $opts{project},
		quiet   => $opts{quiet}   // 0,
		emulate => $opts{emulate} // 0,
		log     => $log,
	}, $class;

	return $self;
}

sub run ( $class, @argv )
{
	# The object exists before the parse, because each command body
	# is a method on it. _prepare fills in what the global options
	# decided, once Fugu::CLI has read them.
	my $self = $class->new;

	my %commands;
	for my $name ( keys %COMMANDS ) {
		my $entry = $COMMANDS{$name};
		$commands{$name} = {
			%$entry,
			run => sub ( $cli, @args ) {
				my $failure = $self->_prepare( $cli, $entry );
				return $failure if defined $failure;

				my $method = $entry->{method};
				return $self->$method( $cli, @args )
				    if $self->can($method);

				# The entry names an App::FuguVM::Guest
				# lifecycle verb. Load the VM and call it;
				# 'up' and 'stop' each read one option.
				my $vm = $self->_load_vm(
					no_cache => $cli->option('no-cache')
					    // 0 )
				    or return EXIT_VM_NOT_FOUND;
				my @verb_args =
				    $method eq 'stop'
				    ? ( $cli->option('force') // 0 )
				    : ();

				return $vm->$method(@verb_args);
			},
		};
	}

	my $cli = Fugu::CLI->new(
		name     => 'fuguvm',
		usage    => '[--vm <name>] <command> [options]',
		log      => $self->{log},
		commands => \%commands,
		options  => {
			'vm=s' =>
			    'the VM to operate on (default: the default_vm '
			    . 'directive, or "default")',
			'project=s' =>
			    'the project root (default: auto-discover)',
			'quiet|q'   => 'suppress informational output',
			'verbose|v' => 'increase verbosity',
			'emulate'   => 'force TCG emulation',
		},
		epilogue => <<'EOF',
Examples:
  fuguvm init
  fuguvm up
  fuguvm ssh "uname -a"
  fuguvm wait --timeout=300
  fuguvm --vm minimal up
EOF
	);

	return $cli->run(@argv);
}

# $self->_prepare($cli, $entry):
#	Apply the global options and load the project. The method
#	returns undef when the command may run, and an exit code when
#	it may not.
sub _prepare ( $self, $cli, $entry )
{
	$self->{vm_name} = $cli->option('vm') // 'default';
	$self->{project} = $cli->option('project');
	$self->{emulate} = $cli->option('emulate') // 0;

	if ( $cli->option('quiet') ) {
		$self->{quiet} = 1;
		$self->{log}   = Fugu::Log->new(
			mode  => Fugu::Log::MODE_QUIET,
			ident => 'fuguvm',
		);
	}
	elsif ( $cli->option('verbose') ) {
		$self->{log}->set_level('debug');
	}

	return if $entry->{offline};

	my $project_root = $self->{project}
	    // App::FuguVM::Config->find_project_root;
	if ( !defined $project_root ) {
		$self->{log}->error(
			"Not in a FuguVM project. Run 'fuguvm init' first.");
		return EXIT_CONFIG_ERROR;
	}
	if ( !-d $project_root ) {
		$self->{log}
		    ->error("Project path does not exist: $project_root");
		return EXIT_CONFIG_ERROR;
	}

	$self->{config} = App::FuguVM::Config->new($project_root);

	# The configuration names the default VM. The option wins; the
	# offline commands, which return before the configuration
	# exists, keep the literal 'default' from above.
	$self->{vm_name} = $cli->option('vm') // $self->{config}->default_vm;

	# State->new diagnoses its own failure
	$self->{state} = App::FuguVM::State->new( $self->{config}->state_dir,
		$self->{vm_name} );
	return EXIT_ERROR if !defined $self->{state};

	return;
}

sub _load_vm ( $self, %opts )
{
	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	if ( !defined $vm_config ) {
		$self->{log}->error("VM '$self->{vm_name}' not found");
		return;
	}

	return App::FuguVM::Guest->new(
		config   => $vm_config,
		state    => $self->{state},
		log      => $self->{log},
		emulate  => $self->{emulate},
		no_cache => $opts{no_cache} // 0,
	);
}

# Show the VM status
sub cmd_status ( $self, $cli, @args )
{
	my $vm = $self->_load_vm or return EXIT_VM_NOT_FOUND;

	$self->_dump_sorted( $vm->status );
	return EXIT_SUCCESS;
}

# $self->_dump_sorted($hash):
#	Log the hash as sorted "key: value" lines.
sub _dump_sorted ( $self, $hash )
{
	for my $key ( sort keys %$hash ) {
		my $value = $hash->{$key} // '';
		$self->{log}->info("$key: $value");
	}

	return;
}

# Open an SSH session into the VM, or run a command
sub cmd_ssh ( $self, $cli, @args )
{
	my $vm = $self->_load_vm or return EXIT_VM_NOT_FOUND;

	# The connection uses the SSH agent for authentication. Connect
	# over IPv4: QEMU forwards the guest SSH port on 127.0.0.1 only.
	# On dual-stack hosts, for example CI runners, 'localhost'
	# resolves to ::1 first.
	my $ssh = Fugu::SSH->new(
		host => '127.0.0.1',
		port => $vm->ssh_port,
		user => 'root',
	);

	if (@args) {
		my $result = $ssh->run_command( join( ' ', @args ) );
		print $result->{stdout}        if $result->{stdout};
		print STDERR $result->{stderr} if $result->{stderr};
		return $result->{exit_code};
	}
	else {
		return $ssh->interactive;
	}
}

# Show the console connection info
sub cmd_console ( $self, $cli, @args )
{
	my $vm   = $self->_load_vm or return EXIT_VM_NOT_FOUND;
	my $port = $vm->console_port;
	$self->{log}->info("Connect with: telnet localhost $port");
	$self->{log}->info("type: telnet");
	$self->{log}->info("host: localhost");
	$self->{log}->info("port: $port");
	return EXIT_SUCCESS;
}

# Run an expect script
sub cmd_expect ( $self, $cli, @args )
{
	my $script = shift @args;
	if ( !defined $script ) {
		$self->{log}->error("Usage: fuguvm expect <script> [args...]");
		return EXIT_INVALID_ARGS;
	}

	my $vm     = $self->_load_vm or return EXIT_VM_NOT_FOUND;
	my $expect = App::FuguVM::Console->new(
		host => 'localhost',
		port => $vm->console_port,
	);

	my $result = $expect->run_script( $script, @args );
	return $result ? EXIT_SUCCESS : EXIT_EXPECT_FAILED;
}

# Wait for SSH to become available
sub cmd_wait ( $self, $cli, @args )
{
	my $timeout = $cli->option('timeout') // 120;

	# Make sure that the timeout is a positive integer
	if ( $timeout !~ /^[1-9][0-9]*$/ ) {
		$self->{log}->error("Invalid timeout value: $timeout");
		return EXIT_INVALID_ARGS;
	}

	my $vm = $self->_load_vm or return EXIT_VM_NOT_FOUND;

	if ( !$vm->wait_ssh($timeout) ) {
		$self->{log}->error("Timeout waiting for SSH");
		return EXIT_TIMEOUT;
	}

	$self->{log}->info("VM ready");
	return EXIT_SUCCESS;
}

# Installed-image cache management
sub cmd_cache ( $self, $cli, @args )
{
	my $action = shift @args;
	if ( !defined $action || $action !~ /^(list|clear)$/ ) {
		$self->{log}
		    ->error("Usage: fuguvm cache <list|clear [--stale]>");
		return EXIT_INVALID_ARGS;
	}

	my $cache = App::FuguVM::DiskCache->new( $self->{config}->cache_dir );

	return $self->_cache_list($cache) if $action eq 'list';
	return $self->_cache_clear( $cli, $cache, @args );
}

# $self->_cache_list($cache):
#	Show one line for each cached entry. Mark the entry that the
#	configuration of the invoked VM currently derives. Then show
#	what the proxy holds.
sub _cache_list ( $self, $cache )
{
	my $entries = $cache->list;
	if ( !@$entries ) {
		$self->{log}->info("No cached images");
		return $self->_proxy_list;
	}

	my $current = $self->_current_cache_key($cache);

	for my $entry (@$entries) {
		my $created =
		    defined $entry->{created_at}
		    ? scalar localtime $entry->{created_at}
		    : 'unknown';
		my $marker = defined $current
		    && $entry->{key} eq $current ? ' (current)' : '';

		$self->{log}->info(
			sprintf(
				'  - %s  %s  %s  snapshots: %d%s',
				$entry->{key},
				_format_size( $entry->{size} ),
				$created,
				scalar @{ $entry->{snapshots} },
				$marker
			) );
	}

	return $self->_proxy_list;
}

# $self->_proxy_list:
#	Show what the download cache of the proxy holds, one line for
#	each OpenBSD version. 'cache list' reports it because it shares
#	cache_dir with the images, and the same 'cache clear' prunes
#	it. A half of the directory that nothing printed was a half
#	nobody knew to bound.
sub _proxy_list ($self)
{
	my $cache =
	    App::FuguVM::Proxy::Cache->new( $self->{config}->cache_dir );
	my $files = $cache->list;

	if ( !@$files ) {
		$self->{log}->info('No proxy downloads');
		return EXIT_SUCCESS;
	}

	# Group the sizes per version, because 'clear --stale' prunes
	# at that granularity. The code counts a URL that names no
	# version under '-' and does not drop it. is_cacheable() admits
	# no such URL today. Thus an entry that cannot be pruned is
	# still visible as one.
	my %bytes;
	for my $file (@$files) {
		my ($version) =
		    $file->{url} =~ m{/pub/OpenBSD/(?:syspatch/)?([0-9.]+)/};
		$bytes{ $version // '-' } += $file->{size};
	}

	$self->{log}->info(
		sprintf 'Proxy downloads (%s):',
		_format_size( $cache->size ) );

	for my $version ( sort keys %bytes ) {
		$self->{log}->info( sprintf '  - OpenBSD %s  %s',
			$version, _format_size( $bytes{$version} ) );
	}

	return EXIT_SUCCESS;
}

# $self->_cache_clear($cli, $cache, @args):
#	Remove cached entries. Bare 'clear' removes them all. --stale
#	keeps the entry that the VM named by --vm derives. The key
#	inputs 'version' and 'disk_size' are per-VM. Thus --stale run
#	for one VM does prune bases that another VM would have hit.
sub _cache_clear ( $self, $cli, $cache, @args )
{
	my $stale = $cli->option('stale') // 0;

	# An interrupted store leaves partial trees behind. Both forms
	# of 'clear' sweep them.
	my $swept = $cache->sweep_temp;
	$self->{log}->info("Removed $swept incomplete cache entries")
	    if $swept;

	# _current_cache_key diagnoses the failure; refuse to prune on it
	my $keep = $stale ? $self->_current_cache_key($cache) : undef;
	return EXIT_ERROR if $stale && !defined $keep;

	my $removed = 0;
	for my $entry ( @{ $cache->list } ) {
		next if defined $keep && $entry->{key} eq $keep;

		my $users   = $self->_disks_backed_by( $entry->{dir} );
		my @running = grep { $_->{running} } @$users;
		if (@running) {
			$self->{log}->error(
				sprintf(
"Cannot remove %s: VM '%s' is running on it",
					$entry->{key}, $running[0]{vm} ) );
			return EXIT_VM_RUNNING;
		}

		# The user can rebuild a stopped disk with
		# 'fuguvm destroy'. Thus this is a warning. The check
		# cannot cover checkouts other than this one. Those
		# checkouts share cache_dir but not state_dir.
		for my $user (@$users) {
			$self->{log}->warning(
				sprintf(
"Removing %s orphans the disk of VM '%s'; run 'fuguvm destroy' for it",
					$entry->{key}, $user->{vm} ) );
		}

		if ( !$cache->remove( $entry->{key} ) ) {
			return EXIT_ERROR;
		}
		$self->{log}->info("Removed $entry->{key}");
		$removed++;
	}

	$self->{log}->info(
		$removed
		? "Removed $removed cached images"
		: "No cached images removed"
	);

	return $self->_proxy_clear($stale);
}

# $self->_proxy_clear($stale):
#	Clear the other half of cache_dir: the download cache of the
#	proxy. Bare 'clear' empties it. --stale keeps the OpenBSD
#	version that the invoked VM installs. That is the same one-VM
#	scope that the image prune above has.
#
#	The image loop cannot reach this cache. That is why this is a
#	second pass, not a branch inside the loop. The two caches share
#	nothing but cache_dir. Also, the images have running-VM and
#	orphaned-disk checks that a re-downloadable file set does not
#	need.
sub _proxy_clear ( $self, $stale )
{
	my $cache =
	    App::FuguVM::Proxy::Cache->new( $self->{config}->cache_dir );

	if ( !$stale ) {
		my $size = $cache->size;
		if ( !$cache->clear ) {
			$self->{log}->error("Cannot clear proxy downloads");
			return EXIT_ERROR;
		}
		$self->{log}->info( sprintf 'Removed %s of proxy downloads',
			_format_size($size) );

		return EXIT_SUCCESS;
	}

	# The --stale path got this far. Thus the VM resolves. To keep
	# its version is the point of the flag.
	my $vm      = $self->{config}->load_vm( $self->{vm_name} );
	my $removed = $cache->prune( $vm->{version} );

	for my $entry (@$removed) {
		$self->{log}->info(
			sprintf 'Removed %s of downloads for OpenBSD %s',
			_format_size( $entry->{size} ),
			$entry->{version} );
	}
	$self->{log}->info('No proxy downloads removed') if !@$removed;

	return EXIT_SUCCESS;
}

# $self->_current_cache_key($cache):
#	Return the key that the configuration of the invoked VM
#	derives. Return undef, with the diagnostic already logged, when
#	the VM or one of the key inputs cannot be resolved.
sub _current_cache_key ( $self, $cache )
{
	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	my $key       = defined $vm_config ? $cache->key($vm_config) : undef;

	$self->{log}->error("Cannot determine the current cache key")
	    if !defined $key;

	return $key;
}

# $self->_disks_backed_by($entry_dir):
#	Return every VM in this checkout whose working disk hangs off
#	an image in $entry_dir, as [ { vm => name, running => bool } ].
#	The method enumerates the state directory, not the
#	configuration. Thus a disk counts whether a 'vm' block still
#	declares it or not.
sub _disks_backed_by ( $self, $entry_dir )
{
	my $state_dir = $self->{config}->state_dir;
	return [] if !-d $state_dir;

	opendir my $dh, $state_dir or return [];
	my @names =
	    sort grep { !/^\./ && -f "$state_dir/$_/disk.qcow2" } readdir $dh;
	closedir $dh;

	my $disk = App::FuguVM::Disk->new($state_dir);
	my @users;

	for my $name (@names) {
		my $backing = $disk->backing_file($name);
		next if !defined $backing;
		next if index( $backing, "$entry_dir/" ) != 0;

		my $state = App::FuguVM::State->new( $state_dir, $name );
		push @users,
		    {
			vm      => $name,
			running => $state && $state->is_vm_running ? 1 : 0,
		    };
	}

	return \@users;
}

# Named snapshot layers over a cached base image
sub cmd_snapshot ( $self, $cli, @args )
{
	my $action = shift @args;
	if ( !defined $action || $action !~ /^(save|restore|list|rm)$/ ) {
		$self->{log}->error(
"Usage: fuguvm snapshot <save|restore|rm> <name> | list [--names]"
		);
		return EXIT_INVALID_ARGS;
	}

	my $cache = App::FuguVM::DiskCache->new( $self->{config}->cache_dir );

	return $self->_snapshot_list( $cli, $cache, @args )
	    if $action eq 'list';

	my $name = shift @args;
	if ( !$cache->valid_snapshot_name($name) ) {
		$self->{log}->error(
			"Invalid snapshot name: " . ( $name // '(missing)' ) );
		return EXIT_INVALID_ARGS;
	}

	return $self->_snapshot_save( $cache, $name ) if $action eq 'save';
	return $self->_snapshot_restore( $cache, $name )
	    if $action eq 'restore';
	return $self->_snapshot_remove( $cache, $name );
}

# $self->_snapshot_save($cache, $name):
#	Flatten the stopped working disk into the cache, under the base
#	it was built on. A live overlay is not consistent. Thus the
#	command refuses a running VM and does not copy it.
sub _snapshot_save ( $self, $cache, $name )
{
	my $vm = $self->_load_vm or return EXIT_VM_NOT_FOUND;

	if ( $vm->is_running ) {
		$self->{log}->error("Stop the VM before saving a snapshot");
		return EXIT_VM_RUNNING;
	}

	if ( !$self->{state}->disk_exists ) {
		$self->{log}->error("No disk image. Run 'fuguvm up' first.");
		return EXIT_ERROR;
	}

	if ( !$self->{state}->is_installed ) {
		$self->{log}->error("VM is not installed yet");
		return EXIT_ERROR;
	}

	# The snapshot belongs under the base that the disk hangs off,
	# directly or through another snapshot. To save again after a
	# restore is normal.
	my $key = $self->_disk_cache_key($cache);
	if ( !defined $key ) {
		$self->{log}->error(
"This disk is not built on a cached image, so it cannot be snapshotted."
		);
		$self->{log}->error(
"It was created with --no-cache or 'image_cache no'; recreate it with 'fuguvm destroy' and 'fuguvm up'."
		);
		return EXIT_ERROR;
	}

	$self->{log}->info("Saving snapshot '$name' of $key...");

	my $state = $self->{state};
	my $path  = $cache->snapshot_store(
		$key, $name,
		$state->disk_path,
		{
			installed            => 1,
			installed_ssh_pubkey =>
			    $state->get_installed_ssh_pubkey,
		} );
	if ( !defined $path ) {
		$self->{log}->error("Failed to save snapshot '$name'");
		return EXIT_ERROR;
	}

	$self->{log}->info("Saved snapshot '$name': $path");
	return EXIT_SUCCESS;
}

# $self->_snapshot_restore($cache, $name):
#	Replace the working disk with a fresh overlay on a snapshot.
#	Reseed the state that the disk embodies. The command works from
#	nothing: no disk, no state. Thus a fresh checkout can restore
#	before its first 'up'.
sub _snapshot_restore ( $self, $cache, $name )
{
	my $vm    = $self->_load_vm or return EXIT_VM_NOT_FOUND;
	my $state = $self->{state};

	if ( $vm->is_running ) {
		$self->{log}->error("Stop the VM before restoring a snapshot");
		return EXIT_VM_RUNNING;
	}

	my $key = $self->_current_cache_key($cache)
	    or return EXIT_ERROR;

	my $found = $self->_snapshot_found( $cache, $key, $name )
	    or return EXIT_SNAPSHOT_NOT_FOUND;

	# Disk::create returns early on an existing path. Without this
	# removal, a restore would report success and change nothing.
	my $disk_path = $state->disk_path;
	if ( -f $disk_path ) {
		unlink $disk_path or do {
			$self->{log}->error("Cannot remove $disk_path: $!");
			return EXIT_ERROR;
		};
	}

	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	my $disk      = App::FuguVM::Disk->new( $self->{config}->state_dir );
	my $created =
	    $disk->create( $vm_config->{name}, undef, $found->{path} );
	if ( !defined $created ) {
		$self->{log}->error("Failed to overlay snapshot '$name'");
		return EXIT_ERROR;
	}

	# Reseed what the disk embodies. The next 'fuguvm up' reconciles
	# a checkout whose SSH key differs from the saved one.
	my $meta = $found->{meta};
	$state->mark_installed;
	$state->set_root_password( $meta->{root_password} )
	    if defined $meta->{root_password};
	$state->mark_ssh_key_installed( $meta->{installed_ssh_pubkey} )
	    if defined $meta->{installed_ssh_pubkey};
	$state->data->{cached_from} = "$key/$name";
	$state->save;

	$self->{log}->info("Restored snapshot '$name' of $key");
	return EXIT_SUCCESS;
}

sub _snapshot_list ( $self, $cli, $cache, @args )
{
	my $names = $cli->option('names') // 0;

	my $key = $self->_current_cache_key($cache)
	    or return EXIT_ERROR;

	my $snapshots = $cache->snapshot_list($key);

	# --names writes bare names to stdout, where a shell can read
	# them. The human listing goes through the logger, which writes
	# to stderr and prefixes every line.
	if ($names) {
		say $_->{name} for @$snapshots;
		return EXIT_SUCCESS;
	}

	if ( !@$snapshots ) {
		$self->{log}->info("No snapshots for $key");
		return EXIT_SUCCESS;
	}

	for my $snapshot (@$snapshots) {
		my $created =
		    defined $snapshot->{created_at}
		    ? scalar localtime $snapshot->{created_at}
		    : 'unknown';
		$self->{log}->info(
			sprintf( '  - %s  %s  %s',
				$snapshot->{name},
				_format_size( $snapshot->{size} ),
				$created ) );
	}

	return EXIT_SUCCESS;
}

sub _snapshot_remove ( $self, $cache, $name )
{
	my $key = $self->_current_cache_key($cache)
	    or return EXIT_ERROR;

	$self->_snapshot_found( $cache, $key, $name )
	    or return EXIT_SNAPSHOT_NOT_FOUND;

	if ( !$cache->snapshot_remove( $key, $name ) ) {
		return EXIT_ERROR;
	}

	$self->{log}->info("Removed snapshot '$name'");
	return EXIT_SUCCESS;
}

# $self->_snapshot_found($cache, $key, $name):
#	Look a snapshot up. Diagnose a miss, once for every caller.
sub _snapshot_found ( $self, $cache, $key, $name )
{
	my $found = $cache->snapshot_lookup( $key, $name );

	$self->{log}->error("No snapshot '$name' for $key")
	    if !defined $found;

	return $found;
}

# $self->_disk_cache_key($cache):
#	Return the cache entry that backs the working disk, directly
#	with its base image or through a snapshot of it.
sub _disk_cache_key ( $self, $cache )
{
	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	return if !defined $vm_config;

	# Scalar context: backing_file returns an empty list for a
	# standalone disk. Without scalar context, the empty list would
	# reach key_for_path as no argument at all, not as undef.
	my $disk    = App::FuguVM::Disk->new( $self->{config}->state_dir );
	my $backing = $disk->backing_file( $vm_config->{name} );

	return $cache->key_for_path($backing);
}

# Disk management
sub cmd_disk ( $self, $cli, @args )
{
	my $action = shift @args;
	if ( !defined $action || $action !~ /^(check|repair|info)$/ ) {
		$self->{log}->error("Usage: fuguvm disk <check|repair|info>");
		return EXIT_INVALID_ARGS;
	}

	my $disk = App::FuguVM::Disk->new( $self->{state}{state_dir} );

	if ( $action eq 'info' ) {
		my $info = $disk->info( $self->{vm_name} );
		if ( !defined $info ) {
			$self->{log}->error("Disk not found");
			return EXIT_ERROR;
		}

		$self->_dump_sorted($info);
		return EXIT_SUCCESS;
	}

	if ( $action eq 'check' ) {
		$self->{log}->info("Checking disk image...");
		my $result = $disk->check( $self->{vm_name} );
		if ( !defined $result ) {
			$self->{log}->error("Disk not found");
			return EXIT_ERROR;
		}

		if ( $result->{status} eq 'ok' ) {
			$self->{log}->info("Disk image OK");
			return EXIT_SUCCESS;
		}

		$self->{log}->error("Disk image has errors");
		print $result->{output} if $result->{output};
		return EXIT_ERROR;
	}

	# The action regex above admits 'repair' alone from here
	$self->{log}->info("Repairing disk image...");

	# First, check if the VM runs
	my $vm = $self->_load_vm;
	if ( defined $vm && $vm->is_running ) {
		$self->{log}->error("Cannot repair disk while VM is running");
		return EXIT_ERROR;
	}

	my $ok = $disk->repair( $self->{vm_name} );
	if ($ok) {

		# Clear the unclean shutdown state after a successful
		# repair
		$self->{state}->clear_shutdown_state;
		$self->{log}->info("Disk repaired");
		return EXIT_SUCCESS;
	}

	$self->{log}->error("Disk repair failed");
	return EXIT_ERROR;
}

# Initialize the project
sub cmd_init ( $self, $cli, @args )
{
	my $dir         = shift @args // '.';
	my $data_dir    = App::FuguVM::Config::DATA_DIR();
	my $fuguvm_dir  = "$dir/$data_dir";
	my $config_file = "$dir/" . App::FuguVM::Config::PROJECT_CONFIG();

	if ( -f $config_file ) {
		$self->{log}->info("FuguVM already initialized in $dir");
		return EXIT_SUCCESS;
	}

	# Fugu::File diagnoses a directory it cannot create or write
	for my $dir ( "$fuguvm_dir/vms", "$fuguvm_dir/state" ) {
		Fugu::File->ensure_dir($dir) or return EXIT_ERROR;
	}

	# Create the project configuration. state_dir must agree with
	# the directory created above. Thus it derives from the same
	# constant.
	my $wrote_config = Fugu::File->write( $config_file, <<"EOF" );
# FuguVM project configuration

cache_dir = ~/.cache/fuguvm
state_dir = $data_dir/state
default_vm = default
EOF
	return EXIT_ERROR if !$wrote_config;

	# Create the default VM config
	my $wrote_vm =
	    Fugu::File->write( "$fuguvm_dir/vms/default.conf", <<"EOF" );
# Default OpenBSD VM

name = openbsd-default
version = 7.8
memory = 2048
disk_size = 8G

ssh_port = 2222
console_port = 4444
EOF
	return EXIT_ERROR if !$wrote_vm;

	# Create the .gitignore file
	my $wrote_ignore =
	    Fugu::File->write( "$fuguvm_dir/.gitignore", <<'EOF' );
state/
*.log
EOF
	return EXIT_ERROR if !$wrote_ignore;

	$self->{log}->info("Initialized FuguVM in $dir");
	return EXIT_SUCCESS;
}

# _format_size($bytes):
#	Return a byte count in the shortest unit that keeps it under
#	1024. A count of undef reads as a question mark: a size that
#	nobody could measure is not a size of zero.
#
#	The command-line interface is the only caller. A byte count for
#	a person to read is presentation, so it belongs here.
sub _format_size ( $bytes = undef )
{
	return '?' if !defined $bytes;

	my @units = ( 'B', 'K', 'M', 'G', 'T' );
	my $size  = $bytes;
	my $unit  = 0;

	while ( $size >= 1024 && $unit < $#units ) {
		$size /= 1024;
		$unit++;
	}

	return $unit == 0
	    ? sprintf( '%d%s',   $size, $units[$unit] )
	    : sprintf( '%.1f%s', $size, $units[$unit] );
}

1;
