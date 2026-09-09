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
our $VERSION = '0.2.0';

use File::Basename;
use File::Spec ();
use Fugu::CLI;
use Fugu::File;
use Fugu::Log;
use App::FuguVM::Config;
use App::FuguVM::Disk;
use App::FuguVM::Console;
use App::FuguVM::DiskCache;
use App::FuguVM::Mirror;
use App::FuguVM::Proxy;
use App::FuguVM::Remote;
use App::FuguVM::State;
use App::FuguVM::Guest;

# The generic exit codes come from Fugu::CLI. Only the codes that
# mean something to a VM are defined here. App::FuguVM::Guest defines
# the codes that it returns itself: this module loads it, and the
# reverse import would be a cycle.
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
		usage   => '[key]',
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
		usage   => '[--] [command [argument ...]]',
		method  => 'cmd_ssh',
	},
	put => {
		summary => 'Copy a local file or directory into the VM',
		usage   => '[--mode=<octal>] <local> <remote>',
		options => { 'mode=s' => 'the mode of each written file' },
		method  => 'cmd_put',
	},
	get => {
		summary => 'Copy one guest file to the host',
		usage   => '<remote> <local>',
		method  => 'cmd_get',
	},
	console => {
		summary => 'Attach to the VM serial console',
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
	mirror => {
		summary => 'Fetch and verify OpenBSD mirror files',
		usage   => '<fetch <file>|verify>',
		method  => 'cmd_mirror',
	},
	snapshot => {
		summary => 'Manage snapshots (save, restore, rm, list)',
		usage   => '<save|restore|rm|list> [name] [--names]',
		options => { 'names' => 'print names only' },
		method  => 'cmd_snapshot',
	},
	image => {
		summary => 'Export the installed base image',
		usage   => 'export <path> [--format=qcow2|raw]',
		options => { 'format=s' => 'the output format: qcow2 or raw' },
		method  => 'cmd_image',
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
				    or return $self->{load_exit};
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
  fuguvm ssh -- uname -a
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

# $self->_load_vm(%opts):
#	Load the invoked VM, or return undef with the exit code in
#	$self->{load_exit}. An unknown configuration value gives
#	EXIT_CONFIG_ERROR. A VM that no file declares gives
#	EXIT_VM_NOT_FOUND.
sub _load_vm ( $self, %opts )
{
	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	if ( !defined $vm_config ) {
		my $reason = $self->{config}->error;
		$self->{load_exit} =
		    defined $reason ? EXIT_CONFIG_ERROR : EXIT_VM_NOT_FOUND;
		$self->{log}
		    ->error( $reason // "VM '$self->{vm_name}' not found" );
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

# Show the VM status. The report is data, so it goes to standard
# output whatever --quiet says. An optional key argument selects one
# bare value, so a make target reads one port without a text filter.
sub cmd_status ( $self, $cli, @args )
{
	my ( $key, @extra ) = @args;
	if (@extra) {
		$self->{log}->error('Usage: fuguvm status [key]');
		return EXIT_INVALID_ARGS;
	}

	my $vm     = $self->_load_vm or return $self->{load_exit};
	my $status = $vm->status;

	if ( defined $key ) {
		if ( !exists $status->{$key} ) {
			$self->{log}->error(
				sprintf(
					"Unknown status key '%s' (valid keys:"
					    . ' %s)',
					$key, join( ', ', sort keys %$status ) )
			);
			return EXIT_INVALID_ARGS;
		}

		say $status->{$key} // '';
		return EXIT_SUCCESS;
	}

	$self->_dump_sorted($status);
	return EXIT_SUCCESS;
}

# $self->_dump_sorted($hash):
#	Write the hash as sorted "key: value" lines to standard
#	output, where a shell can read them. A line with an empty
#	value ends with the colon and one space, so every line has one
#	shape.
sub _dump_sorted ( $self, $hash )
{
	for my $key ( sort keys %$hash ) {
		my $value = $hash->{$key} // '';
		say "$key: $value";
	}

	return;
}

# $self->_require_port($vm, $directive):
#	Return the resolved port of the guest, or undef with a
#	diagnostic. A stopped guest with a directive of 'auto' has no
#	port, and a connection with an undef port would reach the
#	default port of the protocol on the host itself.
sub _require_port ( $self, $vm, $directive )
{
	my $port = $directive eq 'ssh_port' ? $vm->ssh_port : $vm->console_port;
	return $port if defined $port;

	$self->{log}->error( "VM '$self->{vm_name}' has no $directive now."
		    . " Run 'fuguvm up' first." );
	return;
}

# $self->_require_running($vm):
#	Return 1 while the guest runs. Log one line and return 0
#	otherwise, because a clear message beats a "Failed to connect"
#	from libssh2.
sub _require_running ( $self, $vm )
{
	return 1 if $vm->is_running;

	$self->{log}->error( "VM '$self->{vm_name}' does not run."
		    . " Run 'fuguvm up' first." );
	return 0;
}

# $self->_require_remote($vm, $directive):
#	Return the App::FuguVM::Remote object of the guest, or undef.
#	The guest must run, and the port of $directive must resolve.
#	_require_running and _require_port each log the reason.
sub _require_remote ( $self, $vm, $directive )
{
	return if !$self->_require_running($vm);

	my $port = $self->_require_port( $vm, $directive );
	return if !defined $port;

	# The connection uses the SSH agent for authentication. Connect
	# to the IPv4 address that the forwarded port binds to. A name
	# such as 'localhost' resolves to ::1 first on a dual-stack
	# host, and QEMU does not listen there.
	return App::FuguVM::Remote->new(
		host => $vm->connect_address,
		port => $port,
	);
}

# Open an SSH session into the VM, or run one argument vector on it
sub cmd_ssh ( $self, $cli, @args )
{
	my $vm = $self->_load_vm or return $self->{load_exit};

	my $remote = $self->_require_remote( $vm, 'ssh_port' );
	return EXIT_ERROR if !defined $remote;

	if (@args) {
		my $result = $remote->run(@args);
		print $result->{stdout}        if $result->{stdout};
		print STDERR $result->{stderr} if $result->{stderr};
		return $result->{exit_code};
	}
	else {
		return $remote->interactive;
	}
}

# Copy a local file or a local directory into the guest
sub cmd_put ( $self, $cli, @args )
{
	my ( $local, $remote_path, @extra ) = @args;
	if ( !defined $local || !defined $remote_path || @extra ) {
		$self->{log}->error(
			'Usage: fuguvm put [--mode=<octal>] <local> <remote>');
		return EXIT_INVALID_ARGS;
	}
	if ( index( $remote_path, '/' ) != 0 ) {
		$self->{log}
		    ->error("The remote path is not absolute: $remote_path");
		return EXIT_INVALID_ARGS;
	}

	my $mode = $cli->option('mode');
	if ( defined $mode && $mode !~ /^[0-7]{3,4}$/ ) {
		$self->{log}->error(
			"Invalid --mode value: $mode (3 or 4 octal digits)");
		return EXIT_INVALID_ARGS;
	}
	if ( -l $local || ( !-f $local && !-d $local ) ) {
		$self->{log}
		    ->error("Not a regular file or a directory: $local");
		return EXIT_INVALID_ARGS;
	}

	my $vm = $self->_load_vm or return $self->{load_exit};

	my $remote = $self->_require_remote( $vm, 'ssh_port' );
	return EXIT_ERROR if !defined $remote;

	return EXIT_ERROR
	    if !$remote->put( $local, $remote_path,
		defined $mode ? ( mode => oct($mode) ) : () );

	return EXIT_SUCCESS;
}

# Copy one guest file to the host
sub cmd_get ( $self, $cli, @args )
{
	my ( $remote_path, $local, @extra ) = @args;
	if ( !defined $remote_path || !defined $local || @extra ) {
		$self->{log}->error('Usage: fuguvm get <remote> <local>');
		return EXIT_INVALID_ARGS;
	}
	if ( index( $remote_path, '/' ) != 0 ) {
		$self->{log}
		    ->error("The remote path is not absolute: $remote_path");
		return EXIT_INVALID_ARGS;
	}
	if ( -d $local ) {
		$self->{log}
		    ->error("The local destination is a directory: $local");
		return EXIT_INVALID_ARGS;
	}

	my $vm = $self->_load_vm or return $self->{load_exit};

	my $remote = $self->_require_remote( $vm, 'ssh_port' );
	return EXIT_ERROR if !defined $remote;

	# The installed Fugu can come from a release that has no
	# read_file yet: the manifests fetch the unversioned latest
	# asset. A missing method must read as a diagnosis, not as a
	# stack trace.
	if ( !Fugu::SSH->can('read_file') ) {
		$self->{log}->error(
			      'The installed Fugu has no Fugu::SSH->read_file.'
			    . ' Install Fugu 0.2.0 or later.' );
		return EXIT_ERROR;
	}

	return EXIT_ERROR if !$remote->get( $remote_path, $local );

	return EXIT_SUCCESS;
}

# Attach the terminal of the operator to the serial console
sub cmd_console ( $self, $cli, @args )
{
	my $vm = $self->_load_vm or return $self->{load_exit};

	return EXIT_ERROR if !$self->_require_running($vm);

	my $port = $self->_require_port( $vm, 'console_port' );
	return EXIT_ERROR if !defined $port;

	my $host = $vm->connect_address;

	# The line goes through the logger, so --quiet drops it and
	# the attachment still happens.
	$self->{log}
	    ->info("Attaching to $host:$port. Leave with Ctrl-], then 'quit'.");

	my $console = App::FuguVM::Console->new(
		host => $host,
		port => $port,
	);

	return $console->attach;
}

# Run an expect script
sub cmd_expect ( $self, $cli, @args )
{
	my $script = shift @args;
	if ( !defined $script ) {
		$self->{log}->error("Usage: fuguvm expect <script> [args...]");
		return EXIT_INVALID_ARGS;
	}

	my $vm = $self->_load_vm or return $self->{load_exit};

	my $port = $self->_require_port( $vm, 'console_port' );
	return EXIT_ERROR if !defined $port;

	my $expect = App::FuguVM::Console->new(
		host => $vm->connect_address,
		port => $port,
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

	my $vm = $self->_load_vm or return $self->{load_exit};

	my $port = $self->_require_port( $vm, 'ssh_port' );
	return EXIT_ERROR if !defined $port;

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
#	each OpenBSD version, and one line for the distfile tree.
#	'cache list' reports it because it shares cache_dir with the
#	images, and the same 'cache clear' prunes it. A half of the
#	directory that nothing printed was a half nobody knew to bound.
sub _proxy_list ($self)
{
	my $cache = $self->_proxy_cache;
	my $files = $cache->list;

	if ( !@$files ) {
		$self->{log}->info('No proxy downloads');
		return EXIT_SUCCESS;
	}

	# Group the sizes per version, because 'clear --stale' prunes
	# at that granularity. The code counts a URL that names no
	# version under '-' and does not drop it. Thus an entry that
	# cannot be pruned is still visible as one. A distfile carries
	# no version, so the grouping excludes the distfile tree: its
	# own line below reports it against the cap.
	my %bytes;
	for my $file (@$files) {
		next if $file->{url} =~ m{/pub/OpenBSD/distfiles/};
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

	# The distfile line: the size against the cap, or the size with
	# a note that nothing bounds new content. The line stays absent
	# while the tree is empty.
	my $distfiles = $cache->distfile_size;
	my $limit     = $cache->distfile_limit;
	if ( $distfiles > 0 ) {
		$self->{log}->info(
			$limit > 0
			? sprintf(
				'Distfiles: %s of %s',
				_format_size($distfiles),
				_format_size($limit) )
			: sprintf( 'Distfiles: %s, caching off',
				_format_size($distfiles) ) );
	}

	return EXIT_SUCCESS;
}

# $self->_proxy_cache:
#	Build the proxy cache of the project, with the distfile cap of
#	the configuration.
sub _proxy_cache ($self)
{
	return App::FuguVM::Proxy::Cache->new( $self->{config}->cache_dir,
		$self->{config}->distfile_cache );
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
	my $cache = $self->_proxy_cache;

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

	# A distfile carries no version, so the version rule above
	# cannot decide about the distfile tree. --stale keeps the
	# tree, because a refill is expensive, and re-applies the cap.
	# With a cap of 0 no cap applies here, and the flag keeps the
	# whole tree.
	if ( $cache->distfile_limit > 0 ) {
		my $trimmed = $cache->trim_distfiles;
		if (@$trimmed) {
			my $bytes = 0;
			$bytes += $_->{size} for @$trimmed;
			$self->{log}->info( sprintf 'Removed %s of distfiles',
				_format_size($bytes) );
		}
	}

	return EXIT_SUCCESS;
}

# The mirror subcommand: fetch one verified file of the release, or
# verify the cached files of the version and the architecture of the
# invoked guest.
sub cmd_mirror ( $self, $cli, @args )
{
	my $action = shift @args;
	if ( !defined $action || $action !~ /^(fetch|verify)$/ ) {
		$self->{log}
		    ->error('Usage: fuguvm mirror <fetch <file>|verify>');
		return EXIT_INVALID_ARGS;
	}

	my $vm_config = $self->{config}->load_vm( $self->{vm_name} );
	if ( !defined $vm_config ) {
		my $reason = $self->{config}->error;
		$self->{log}
		    ->error( $reason // "VM '$self->{vm_name}' not found" );
		return defined $reason ? EXIT_CONFIG_ERROR : EXIT_VM_NOT_FOUND;
	}

	# The verify verb proves; a 'verify no' directive must not turn
	# it into a walk that proves nothing.
	my $verifies = $action eq 'verify' ? 1 : $vm_config->{verify} // 1;
	my $mirror   = App::FuguVM::Mirror->new(
		cache   => $self->_proxy_cache,
		version => $vm_config->{version},
		arch    => $vm_config->{arch},
		verify  => $verifies,
		(
			defined $vm_config->{signify_dir}
			? ( keys_dir => $vm_config->{signify_dir} )
			: ()
		),
	);

	# An absent public key for the version is a configuration
	# error, apart from a failed download or a failed signature.
	if ( $verifies && !defined $mirror->key_path ) {
		$self->{log}->error( $mirror->error );
		return EXIT_CONFIG_ERROR;
	}

	if ( $action eq 'verify' ) {
		if (@args) {
			$self->{log}->error('Usage: fuguvm mirror verify');
			return EXIT_INVALID_ARGS;
		}
		return $self->_mirror_verify($mirror);
	}
	return $self->_mirror_fetch( $mirror, @args );
}

# $self->_mirror_fetch($mirror, @args):
#	Fetch, verify and cache one file of the release, and write the
#	cached path to standard output, where a script can read it.
#	The scope comes from the manifests: the release scope when the
#	manifest of the architecture directory names the file, and the
#	source scope otherwise. Both manifests are authoritative
#	lists, so the tool guesses nothing.
sub _mirror_fetch ( $self, $mirror, @args )
{
	my ( $file, @extra ) = @args;
	if ( !defined $file || @extra ) {
		$self->{log}->error('Usage: fuguvm mirror fetch <file>');
		return EXIT_INVALID_ARGS;
	}

	my $scope;
	for my $candidate (qw(release source)) {
		my $names = $mirror->manifest_names($candidate);
		if ( !defined $names ) {
			$self->{log}->error( $mirror->error );
			return EXIT_ERROR;
		}
		if ( grep { $_ eq $file } @$names ) {
			$scope = $candidate;
			last;
		}
	}
	if ( !defined $scope ) {
		$self->{log}->error("No manifest of the release names '$file'");
		return EXIT_ERROR;
	}

	my $path = $mirror->ensure( $scope, $file );
	if ( !defined $path ) {
		$self->{log}->error( $mirror->error );
		return EXIT_ERROR;
	}

	say $path;
	return EXIT_SUCCESS;
}

# $self->_mirror_verify($mirror):
#	Verify every cached file of the two scopes. The verb removes
#	each file that failed, in its own scope only, because a file
#	that fails a digest must not stay in a cache that a later run
#	reads and a same-named file of the other scope failed nothing.
#	It must not remove an unknown file: a name that no manifest
#	holds is not a failure, and index.txt is such a name on every
#	mirror. The verb is idempotent: a second run over a clean
#	cache removes nothing and exits 0.
sub _mirror_verify ( $self, $mirror )
{
	my $report = $mirror->verify_cache;
	if ( !defined $report ) {
		$self->{log}->error( $mirror->error );
		return EXIT_ERROR;
	}

	for my $entry ( @{ $report->{failed} } ) {
		$self->{log}->error( sprintf 'Verification failed: %s/%s',
			$entry->{scope}, $entry->{name} );
		my $path =
		    $mirror->cached_path( $entry->{scope}, $entry->{name} );
		unlink $path if defined $path && -f $path;
	}

	$self->{log}->info(
		sprintf 'Verified: %d ok, %d failed, %d unknown',
		scalar @{ $report->{ok} },
		scalar @{ $report->{failed} },
		scalar @{ $report->{unknown} } );

	return @{ $report->{failed} } ? EXIT_ERROR : EXIT_SUCCESS;
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
	my $vm = $self->_load_vm or return $self->{load_exit};

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
	my $vm    = $self->_load_vm or return $self->{load_exit};
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
	$state->mark_installed( $vm_config->{arch} );
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

# The image export, beside the snapshot verbs. Those verbs already
# resolve a cache key from a working disk, and the export needs the
# same resolution.
sub cmd_image ( $self, $cli, @args )
{
	my $action = shift @args;
	if ( !defined $action || $action ne 'export' ) {
		$self->{log}->error( 'Usage: fuguvm image export <path>'
			    . ' [--format=qcow2|raw]' );
		return EXIT_INVALID_ARGS;
	}

	return $self->_image_export( $cli, @args );
}

# $self->_image_export($cli, @args):
#	Write the base image of the invoked VM as a full-disk image.
#	The source is the base image of the cache entry that backs the
#	working disk, or the working disk itself when the disk is
#	standalone. The write goes through one temporary sibling and
#	one rename, so a failure leaves no partial file behind.
sub _image_export ( $self, $cli, @args )
{
	my ( $target, @extra ) = @args;
	if ( !defined $target || @extra ) {
		$self->{log}->error( 'Usage: fuguvm image export <path>'
			    . ' [--format=qcow2|raw]' );
		return EXIT_INVALID_ARGS;
	}

	my $format = $cli->option('format') // 'qcow2';
	if ( $format ne 'qcow2' && $format ne 'raw' ) {
		$self->{log}->error(
			"Unknown format '$format' (accepted values: qcow2, raw)"
		);
		return EXIT_INVALID_ARGS;
	}

	my $vm = $self->_load_vm or return $self->{load_exit};

	# A live overlay is not consistent, and a running QEMU holds
	# an exclusive lock on the working disk. snapshot save refuses
	# a running guest for the same reason.
	if ( $vm->is_running ) {
		$self->{log}->error("Stop the VM before exporting its image");
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

	# The tool must not overwrite an image that an operator
	# published.
	if ( -e $target ) {
		$self->{log}->error("The target exists: $target");
		return EXIT_ERROR;
	}

	# The tool creates no directory for the operator
	my $parent = dirname($target);
	if ( !-d $parent ) {
		$self->{log}->error("The parent directory is absent: $parent");
		return EXIT_ERROR;
	}

	# The source. A standalone disk comes from --no-cache or from
	# 'image_cache no', and the export then reads the disk itself.
	my $cache = App::FuguVM::DiskCache->new( $self->{config}->cache_dir );
	my $key   = $self->_disk_cache_key($cache);
	my $source =
	    defined $key ? $cache->base_path($key) : $self->{state}->disk_path;

	my $tmp = "$target.tmp.$$";
	if ( !App::FuguVM::Disk->convert( $source, $tmp, format => $format ) ) {
		unlink $tmp;
		$self->{log}->error("Export failed");
		return EXIT_ERROR;
	}
	if ( !rename $tmp, $target ) {
		$self->{log}->error("Cannot publish $target: $!");
		unlink $tmp;
		return EXIT_ERROR;
	}

	my $path = File::Spec->rel2abs($target);
	$self->_dump_sorted( {
		bytes  => -s $path,
		format => $format,
		key    => $key // '',
		path   => $path,
		source => File::Spec->rel2abs($source),
	} );

	return EXIT_SUCCESS;
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
arch = arm64
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
