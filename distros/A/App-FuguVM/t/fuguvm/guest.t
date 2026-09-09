#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);

# The load is a hard failure, not a skip. Fugu::SSH requires Net::SSH2
# lazily, so this module loads with core Perl alone: an eval guard here
# could only ever hide a rename or a syntax error, which are the two
# failures it must report.
use_ok('App::FuguVM::Guest');

# Memory and CPU constants
{
	ok(defined &App::FuguVM::Guest::MEMORY_DEFAULT, 'MEMORY_DEFAULT defined');
	is(App::FuguVM::Guest::MEMORY_DEFAULT(), '1G', 'Default memory is 1G');
	ok(defined &App::FuguVM::Guest::CPU_COUNT, 'CPU_COUNT defined');
	is(App::FuguVM::Guest::CPU_COUNT(), 2, 'Default CPU count is 2');
}

# Exit code constants
{
	is(App::FuguVM::Guest::EXIT_SUCCESS(), 0, 'EXIT_SUCCESS is 0');
	is(App::FuguVM::Guest::EXIT_ERROR(), 1, 'EXIT_ERROR is 1');
	is(App::FuguVM::Guest::EXIT_CONFIG_ERROR(), 3,
	    'EXIT_CONFIG_ERROR is 3');
	is(App::FuguVM::Guest::EXIT_VM_RUNNING(), 5, 'EXIT_VM_RUNNING is 5');
	is(App::FuguVM::Guest::EXIT_TIMEOUT(), 7, 'EXIT_TIMEOUT is 7');
}

# The configured architecture, at the boundary the loader validated
{
	my $vm = App::FuguVM::Guest->new(config => { arch => 'amd64' });
	is($vm->_arch->name, 'amd64',
	    '_arch returns the object of the configured value');
	is($vm->_arch->qemu_binary, 'qemu-system-x86_64',
	    'and the object carries the table');

	my $broken = App::FuguVM::Guest->new(config => { arch => 'mips64' });
	ok(!eval { $broken->_arch; 1 },
	    '_arch dies on an unknown value: the loader is the boundary');
	like($@, qr/unknown architecture/, 'and the death names the cause');
}

# Accelerator selection
{
	# --emulate always forces TCG with the named CPU model of the
	# architecture
	for my $case (['arm64', 'cortex-a57'], ['amd64', 'qemu64']) {
		my ($arch, $tcg_cpu) = @$case;
		my $emulated = App::FuguVM::Guest->new(
			emulate => 1,
			config  => { arch => $arch },
		);
		my %args = ($emulated->_accel_args);
		is($args{'-accel'}, 'tcg', "--emulate forces TCG for $arch");
		is($args{'-cpu'}, $tcg_cpu,
		    "TCG pairs with the $arch model, not host passthrough");
	}

	# Auto-selection returns a consistent accel/cpu pair
	my $auto = App::FuguVM::Guest->new(config => { arch => 'arm64' });
	my %args = ($auto->_accel_args);
	like($args{'-accel'}, qr/^(hvf|kvm|tcg)$/, 'known accelerator');
	if ($args{'-accel'} eq 'tcg') {
		is($args{'-cpu'}, 'cortex-a57',
		    'software emulation pairs with a named CPU');
	} else {
		is($args{'-cpu'}, 'host',
		    'hardware acceleration pairs with host CPU');
	}

	# The host arch helper returns a non-empty machine string
	ok(length(App::FuguVM::Guest::_host_arch()), 'host arch detected');
}

# The QEMU binary lookup on PATH
{
	my $bindir = tempdir(CLEANUP => 1);
	local $ENV{PATH} = $bindir;

	my $vm = App::FuguVM::Guest->new(config => { arch => 'amd64' });
	is($vm->_qemu_path, undef,
	    '_qemu_path returns undef when PATH holds no such binary');

	my $stub = "$bindir/qemu-system-x86_64";
	open my $fh, '>', $stub or die "Cannot write $stub: $!";
	print $fh "#!/bin/sh\n";
	close $fh;
	chmod 0755, $stub or die "Cannot chmod $stub: $!";

	is($vm->_qemu_path, $stub,
	    '_qemu_path returns the path of an executable stub');

	# up and start diagnose the absent binary with exit code 3
	my $arm = App::FuguVM::Guest->new(config =>
	    { name => 'default', arch => 'arm64' });
	$arm->{log} = TestLog->new;
	is($arm->start, App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    'start exits 3 when the QEMU binary is absent');
	like(join("\n", @{ $arm->{log}{errors} }),
	    qr/qemu-system-aarch64.*arm64/,
	    'and the message names the binary and the architecture');
	is($arm->up, App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    'up exits 3 the same way');
}

# The firmware search returns undef, or a code file that exists with
# its variable-store template
{
	my $vm = App::FuguVM::Guest->new(config => { arch => 'amd64' });
	my $firmware = $vm->_find_efi_firmware;
	ok(!defined $firmware || -f $firmware->{code},
	    '_find_efi_firmware returns undef or a code file that exists');
	ok(!defined $firmware || -f $firmware->{vars},
	    'and an amd64 result carries its variable-store template');
}

# The firmware arguments: -bios without a variable store, and two
# pflash devices with one
{
	my $state_dir = tempdir(CLEANUP => 1);
	my $vars = "$state_dir/template-vars.fd";
	open my $fh, '>', $vars or die "Cannot write $vars: $!";
	print $fh 'vars';
	close $fh;

	require App::FuguVM::State;
	my $state = App::FuguVM::State->new($state_dir, 'default');
	my $vm = App::FuguVM::Guest->new(
	    config => { name => 'default', arch => 'amd64' },
	    state  => $state,
	);

	is_deeply([$vm->_firmware_args({ code => '/x/code.fd' })],
	    ['-bios', '/x/code.fd'],
	    'a code file without a variable store boots with -bios');

	my @args = $vm->_firmware_args(
	    { code => '/x/code.fd', vars => $vars });
	is(scalar @args, 4, 'a pair maps to two pflash devices');
	like($args[1], qr/if=pflash.*readonly=on.*\/x\/code\.fd/,
	    'the code device is read-only');
	my ($copy) = $args[3] =~ /file=(.*)$/;
	ok(-f $copy, 'the variable-store copy exists');
	isnt($copy, $vars, 'and it is a copy, not the template');
}

# A disk belongs to one architecture: up stops when the state records
# an other one
{
	require App::FuguVM::State;

	my $bindir = tempdir(CLEANUP => 1);
	my $stub = "$bindir/qemu-system-x86_64";
	open my $fh, '>', $stub or die "Cannot write $stub: $!";
	print $fh "#!/bin/sh\n";
	close $fh;
	chmod 0755, $stub or die "Cannot chmod $stub: $!";
	local $ENV{PATH} = $bindir;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	$state->mark_installed('arm64');

	my $log = TestLog->new;
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'amd64' },
		state  => $state,
		log    => $log,
	);
	is($vm->up, App::FuguVM::Guest::EXIT_ERROR(),
	    'up stops on a disk of an other architecture');
	like(join("\n", @{ $log->{errors} }), qr/fuguvm destroy/,
	    'and the message names the remedy');
	is($vm->start, App::FuguVM::Guest::EXIT_ERROR(),
	    'start stops the same way');
}

# status reports the configured architecture
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => {
			name => 'default', arch => 'amd64',
			ssh_port => 2222, console_port => 4444,
		},
		state => $state,
	);
	is($vm->status->{arch}, 'amd64',
	    'status reports the configured architecture');
}

# Bounded guest interaction: _bounded must return the code's value
# when the code finishes in time. When it does not, _bounded must
# return undef and must not hang. Thus a wedged guest can never
# stall shutdown.
{
	my $vm = App::FuguVM::Guest->new;
	$vm->{log} = TestLog->new;    # swallow the timeout warning

	is($vm->_bounded(5, sub { return 'done' }), 'done',
	    '_bounded returns the code result when it finishes in time');

	my $start = time;
	my $ret = $vm->_bounded(1, sub { sleep 5; return 'late' });
	is($ret, undef, '_bounded returns undef when the deadline elapses');
	ok(time - $start < 4, '_bounded aborts near the deadline, not later');
	ok($vm->{log}{warned}, '_bounded warns on timeout');
}

# The image cache follows the configured cache_dir, which
# App::FuguVM::Config::load_vm injects into the per-VM config.
{
	my $vm = App::FuguVM::Guest->new(config => { cache_dir => '/var/cache/fuguvm' });
	is($vm->_cache_dir, '/var/cache/fuguvm', 'configured cache_dir wins');
	is($vm->_image_cache->installed_dir, '/var/cache/fuguvm/installed',
	    'the image cache uses it too');

	local $ENV{HOME} = '/home/nobody';
	my $bare = App::FuguVM::Guest->new(config => {});
	is($bare->_cache_dir, '/home/nobody/.cache/fuguvm',
	    'a config without cache_dir falls back to the default');
}

# When the cache is off, `up` suppresses restore and save together.
# It derives no key at all. Thus it can neither look one up nor
# publish one.
{
	my $off = App::FuguVM::Guest->new(
		config => { cache_dir => '/var/cache/fuguvm', image_cache => 0 });
	is($off->_image_cache, undef, 'image_cache no disables the cache');

	my $flag = App::FuguVM::Guest->new(
		config   => { cache_dir => '/var/cache/fuguvm' },
		no_cache => 1,
	);
	is($flag->_image_cache, undef, '--no-cache disables the cache');

	my $on = App::FuguVM::Guest->new(
		config => { cache_dir => '/var/cache/fuguvm', image_cache => 1 });
	ok(defined $on->_image_cache, 'image_cache yes leaves it enabled');
}

# Installed-image cache: restore, chain verification, and reparenting.
# These are the parts of `up` that do not need a running QEMU.
SKIP: {
	my $has_qemu = `which qemu-img 2>/dev/null`;
	skip 'qemu-img not installed', 14 unless $has_qemu;

	require App::FuguVM::Disk;
	require App::FuguVM::DiskCache;
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $cache = App::FuguVM::DiskCache->new("$root/cache");
	my $key = '7.8-arm64-11223344';

	# A stand-in for a freshly installed disk
	my $installed = "$root/installed.qcow2";
	system('qemu-img', 'create', '-f', 'qcow2', $installed, '64M') == 0
	    or skip 'cannot create a test disk image', 14;
	my $base = $cache->store($key, $installed,
	    { root_password => 'from-the-image' });
	ok(defined $base, 'a base image is available to restore from');

	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64', cache_dir => "$root/cache" },
		state  => $state,
		log    => TestLog->new,
	);

	# Restore: the overlay plus the state that the installation
	# leaves behind
	ok($vm->_cache_restore($cache, $key), 'restore reports a cache hit');
	ok($state->disk_exists, 'the working disk exists after a restore');
	ok($state->is_installed, 'the restored VM is marked installed');
	is($state->get_root_password, 'from-the-image',
	    'the root password comes from the image, not a new install');
	is($state->data->{cached_from}, $key,
	    'state records which cached image it came from');

	my $disk = App::FuguVM::Disk->new("$root/state");
	is($disk->backing_file('default'), $base,
	    'the working disk is an overlay on the cached base');

	# A resolvable chain passes verification
	ok($vm->_verify_backing_chain, 'an intact backing chain verifies');

	# Reparenting a standalone disk onto a base
	my $other = App::FuguVM::State->new("$root/state2", 'default');
	my $vm2 = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64', cache_dir => "$root/cache" },
		state  => $other,
		log    => TestLog->new,
	);
	App::FuguVM::Disk->new("$root/state2")->create('default', '64M');
	ok($other->disk_exists, 'a standalone disk to reparent');
	ok($vm2->_reparent_disk($base), 'reparent succeeds');
	is(App::FuguVM::Disk->new("$root/state2")->backing_file('default'), $base,
	    'the standalone disk became an overlay');
	ok(!-f $other->disk_path . '.replaced',
	    'no leftover copy of the replaced disk');

	# A missing base is a diagnosed failure, not silent corruption
	chmod 0700, $cache->entry_dir($key);
	unlink $base;
	my $log = TestLog->new;
	$vm->{log} = $log;
	ok(!$vm->_verify_backing_chain, 'a broken chain fails verification');
	like(join("\n", @{ $log->{errors} }), qr/fuguvm destroy/,
	    'and the error names the remedy');

	# A restore against the now-empty cache is a miss, not a crash
	my $fresh = App::FuguVM::State->new("$root/state3", 'default');
	my $vm3 = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64', cache_dir => "$root/cache" },
		state  => $fresh,
		log    => TestLog->new,
	);
	ok(!$vm3->_cache_restore($cache, $key),
	    'restore misses once the base is gone');
}

# The install media arguments: -no-reboot for an autoinstall run
# with media, and for nothing else
{
	my $auto = App::FuguVM::Guest->new(
	    config => { arch => 'amd64', install_mode => 'autoinstall' });
	is_deeply([$auto->_media_args('/x/miniroot.img')],
	    ['-drive', 'file=/x/miniroot.img,format=raw,if=virtio,readonly=on',
		'-no-reboot'],
	    'an autoinstall run with install media adds -no-reboot');
	is_deeply([$auto->_media_args], [],
	    'the restart with no media adds nothing');

	my $expect = App::FuguVM::Guest->new(
	    config => { arch => 'amd64', install_mode => 'expect' });
	is_deeply([$expect->_media_args('/x/miniroot.img')],
	    ['-drive', 'file=/x/miniroot.img,format=raw,if=virtio,readonly=on'],
	    'the expect mode boots its media without -no-reboot');
}

# The root password of each mode
{
	my $root = tempdir(CLEANUP => 1);
	open my $fh, '>', "$root/password" or die $!;
	print $fh "s3cret\nsecond line\n";
	close $fh;
	chmod 0600, "$root/password" or die $!;

	my $imported = App::FuguVM::Guest->new(
		config => { install_mode => 'import',
		    root_password_file => "$root/password" },
		log => TestLog->new,
	);
	is($imported->_root_password, 's3cret',
	    '_root_password returns the first line, with no newline');

	my $bare = App::FuguVM::Guest->new(
		config => { install_mode => 'autoinstall' },
		log    => TestLog->new,
	);
	is($bare->_root_password, undef,
	    'no root_password_file means no password outside expect');

	my $expect = App::FuguVM::Guest->new(
		config => { install_mode => 'expect' },
		log    => TestLog->new,
	);
	my $generated = $expect->_root_password;
	is(length($generated), 32,
	    '_root_password generates a password in the expect mode');
	isnt($expect->_root_password, $generated, 'a fresh one each call');

	# A password file that the group or others can read gives a
	# warning
	chmod 0644, "$root/password" or die $!;
	my $log = TestLog->new;
	my $loud = App::FuguVM::Guest->new(
		config => { install_mode => 'import',
		    root_password_file => "$root/password" },
		log => $log,
	);
	is($loud->_root_password, 's3cret', 'the password still reads');
	ok($log->{warned}, 'and the tool warns about the file mode');
}

# The bind address and the connect address
{
	my $vm = App::FuguVM::Guest->new(
	    config => { bind_address => '10.0.0.1' });
	is($vm->bind_address, '10.0.0.1',
	    'bind_address returns the configured address');
	is($vm->connect_address, '10.0.0.1',
	    'connect_address returns the bind address');

	my $open = App::FuguVM::Guest->new(
	    config => { bind_address => '0.0.0.0' });
	is($open->connect_address, '127.0.0.1',
	    'connect_address is loopback for 0.0.0.0');

	my $bare = App::FuguVM::Guest->new(config => {});
	is($bare->bind_address, '127.0.0.1',
	    'a config without bind_address falls back to the default');
}

# The resolved ports: the record wins, the configured number serves
# without one, and auto with no record has no port
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', ssh_port => 2222,
		    console_port => 4444 },
		state => $state,
	);

	is($vm->ssh_port, 2222,
	    'ssh_port returns the configured number with no record');
	is($vm->console_port, 4444, 'console_port does the same');

	# The record serves while the guest runs
	$state->set_runtime(
	    accel => 'tcg', ssh_port => 2250, console_port => 4470);
	$state->vm_pidfile->write_pid($$);
	is($vm->ssh_port, 2250, 'the recorded port wins while running');
	is($vm->console_port, 4470, 'for both directives');

	# A record that a crash left behind must not read as a live
	# port: the guest is gone, so the configured value serves.
	$state->clear_vm_pid;
	is($vm->ssh_port, 2222,
	    'a stale record does not serve a stopped guest');

	my $fleet = App::FuguVM::Guest->new(
		config => { name => 'default', ssh_port => 'auto',
		    console_port => 'auto' },
		state => $state,
	);
	is($fleet->ssh_port, undef,
	    'auto reports no port for a stopped guest, stale record or not');
	is($fleet->console_port, undef, 'for both directives');

	# stop on a guest that does not run clears the stale record
	$fleet->{log} = TestLog->new;
	is($fleet->stop, App::FuguVM::Guest::EXIT_SUCCESS(),
	    'stop succeeds on a guest that does not run');
	is_deeply($state->get_runtime, {},
	    'and it clears the record that a crash left behind');

	$state->clear_runtime;
	is($fleet->ssh_port, undef, 'auto with no record has no port');
}

# The free-port probe
{
	my $vm = App::FuguVM::Guest->new(
	    config => { bind_address => '127.0.0.1' });

	my $port = $vm->_free_port(41000, 41099, {});
	ok(defined $port && $port >= 41000 && $port <= 41099,
	    '_free_port returns a port of the range that binds');

	my $next = $vm->_free_port(41000, 41099, { $port => 1 });
	isnt($next, $port, '_free_port skips a port the caller names as taken');

	# Fill a short range with listening sockets. The test opens
	# them itself, so it needs no guest. A base whose ports are
	# already busy moves up, so the test stays free of the other
	# users of the machine.
	require IO::Socket::INET;
	my @socks;
	my $base;
	BASE: for (my $candidate = 42000; $candidate < 50000;
	    $candidate += 10) {
		@socks = ();
		for my $p ($candidate .. $candidate + 2) {
			my $sock = IO::Socket::INET->new(
				LocalAddr => '127.0.0.1',
				LocalPort => $p,
				Proto     => 'tcp',
				Listen    => 1,
			);
			if (!defined $sock) {
				next BASE;
			}
			push @socks, $sock;
		}
		$base = $candidate;
		last;
	}
	ok(defined $base, 'three consecutive ports to fill');
	is($vm->_free_port($base, $base + 2, {}), undef,
	    '_free_port returns undef for a range that sockets fill');
	$_->close for @socks;
}

# Port resolution records the ports and the accelerator
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64',
		    ssh_port => 2299, console_port => 4499,
		    cache_dir => "$root/cache" },
		state => $state,
		log   => TestLog->new,
	);

	is($vm->_resolve_ports, undef, '_resolve_ports succeeds');
	my $runtime = $state->get_runtime;
	is($runtime->{ssh_port}, 2299,
	    'a configured number resolves to itself');
	is($runtime->{console_port}, 4499, 'for both directives');
	like($runtime->{accel}, qr/^(hvf|kvm|tcg)$/,
	    'and the record holds the accelerator');
	ok(-f "$root/cache/ports.lock", 'the port lock file exists');

	# A sibling record excludes its ports from the probe
	my $sibling = App::FuguVM::State->new("$root/state", 'other');
	$sibling->set_runtime(
	    accel => 'tcg', ssh_port => 2222, console_port => 4444);

	my $fleet_state = App::FuguVM::State->new("$root/state", 'fleet');
	my $fleet = App::FuguVM::Guest->new(
		config => { name => 'fleet', arch => 'arm64',
		    ssh_port => 'auto', console_port => 'auto',
		    cache_dir => "$root/cache" },
		state => $fleet_state,
		log   => TestLog->new,
	);
	is($fleet->_resolve_ports, undef, '_resolve_ports resolves auto');
	my $resolved = $fleet_state->get_runtime;
	ok($resolved->{ssh_port} >= 2222 && $resolved->{ssh_port} <= 2321,
	    'auto takes a port of the SSH range');
	isnt($resolved->{ssh_port}, 2222,
	    'and skips the port that a sibling records');
	ok($resolved->{console_port} >= 4444
	    && $resolved->{console_port} <= 4543,
	    'auto takes a port of the console range');
	isnt($resolved->{console_port}, 4444,
	    'and skips the console port of the sibling');

	$fleet_state->vm_pidfile->write_pid($$);
	is($fleet->ssh_port, $resolved->{ssh_port},
	    'ssh_port returns the recorded port of the running guest');
	$fleet_state->clear_vm_pid;

	# A probe must not select the fixed port of the other directive
	# of the same guest, and must not select a fixed port of a
	# declared sibling
	my $mixed_state = App::FuguVM::State->new("$root/state", 'mixed');
	my $mixed = App::FuguVM::Guest->new(
		config => { name => 'mixed', arch => 'arm64',
		    ssh_port => 'auto', console_port => 2223,
		    declared_ports => { 2224 => 1 },
		    cache_dir => "$root/cache" },
		state => $mixed_state,
		log   => TestLog->new,
	);
	is($mixed->_resolve_ports, undef,
	    '_resolve_ports resolves a mixed declaration');
	my $mixed_ports = $mixed_state->get_runtime;
	isnt($mixed_ports->{ssh_port}, 2223,
	    'auto skips the fixed port of the other directive');
	isnt($mixed_ports->{ssh_port}, 2224,
	    'auto skips a declared fixed port of the project');
	is($mixed_ports->{console_port}, 2223,
	    'and the fixed port resolves to itself');

	# An exhausted range is a diagnosed failure, not a hang. No
	# host interface holds the documentation address, so no port
	# of the range binds.
	my $dead_state = App::FuguVM::State->new("$root/state", 'dead');
	my $dead = App::FuguVM::Guest->new(
		config => { name => 'dead', arch => 'arm64',
		    ssh_port => 'auto', console_port => 'auto',
		    bind_address => '192.0.2.1',
		    cache_dir => "$root/cache" },
		state => $dead_state,
		log   => TestLog->new,
	);
	is($dead->_resolve_ports, App::FuguVM::Guest::EXIT_ERROR(),
	    'an exhausted range gives EXIT_ERROR');
	like(join("\n", @{ $dead->{log}{errors} }), qr/2222-2321/,
	    'and the message names the range');

	# The port lock is exclusive across processes
	my $locked = $fleet->_lock_ports;
	ok(defined $locked, '_lock_ports returns a handle');
	is(_flock_in_child("$root/cache/ports.lock"), 0,
	    'a child cannot take the held lock');
	close $locked;
	is(_flock_in_child("$root/cache/ports.lock"), 1,
	    'the lock is free once the handle closes');
}

# The accelerator answer: the record wins for a running guest, and
# the current selection serves a stopped one
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64' },
		state  => $state,
	);

	like($vm->accel, qr/^(hvf|kvm|tcg)$/,
	    'accel returns a known name for a stopped guest');

	$state->set_runtime(
	    accel => 'kvm', ssh_port => 2222, console_port => 4444);
	$state->vm_pidfile->write_pid($$);
	is($vm->accel, 'kvm', 'accel returns the recorded value while running');
	$state->clear_vm_pid;

	my $emulated = App::FuguVM::Guest->new(
		config  => { name => 'default', arch => 'arm64' },
		state   => $state,
		emulate => 1,
	);
	is($emulated->accel, 'tcg', '--emulate selects TCG for a stopped guest');
}

# The QEMU network and serial arguments carry the bind address and
# the recorded ports. This assembly enforces the loopback default.
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	$state->set_runtime(
	    accel => 'tcg', ssh_port => 2299, console_port => 4499);

	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64',
		    bind_address => '127.0.0.1' },
		state => $state,
	);
	is(($vm->_network_args)[3],
	    'user,id=net0,hostfwd=tcp:127.0.0.1:2299-:22',
	    'the hostfwd rule carries the bind address and the SSH port');
	is(($vm->_serial_args)[1],
	    'tcp:127.0.0.1:4499,server,telnet,nowait',
	    'the serial listener carries the bind address and the port');

	my $open = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64',
		    bind_address => '0.0.0.0' },
		state => $state,
	);
	like(($open->_network_args)[3],
	    qr/hostfwd=tcp:0\.0\.0\.0:2299-:22/,
	    'bind_address 0.0.0.0 reaches the hostfwd rule');
}

# The version gate
{
	require App::FuguVM::State;

	my $bindir = tempdir(CLEANUP => 1);
	my $stub = "$bindir/qemu-system-x86_64";
	open my $fh, '>', $stub or die "Cannot write $stub: $!";
	print $fh "#!/bin/sh\n";
	print $fh "echo run >> '$bindir/count'\n";
	print $fh "echo 'QEMU emulator version 9.0.4 (v9.0.4)'\n";
	close $fh;
	chmod 0755, $stub or die "Cannot chmod $stub: $!";
	local $ENV{PATH} = $bindir;

	my $gate = sub ($version) {
		my $vm = App::FuguVM::Guest->new(
			config => { name => 'default', arch => 'amd64',
			    ( defined $version
				? ( qemu_version => $version ) : () ) },
			log => TestLog->new,
		);
		return $vm;
	};

	# No directive checks nothing and runs no command
	is($gate->(undef)->_check_qemu_version, undef,
	    '_check_qemu_version passes with no directive');
	ok(!-e "$bindir/count", 'and it runs no command');

	is($gate->('9.0')->_check_qemu_version, undef,
	    '9.0 accepts a reported 9.0.4');
	is($gate->('9.0.4')->_check_qemu_version, undef,
	    '9.0.4 accepts a reported 9.0.4');
	ok(-e "$bindir/count", 'the check runs the binary');

	is($gate->('9.1')->_check_qemu_version,
	    App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    '9.1 refuses a reported 9.0.4');
	is($gate->('9.0.5')->_check_qemu_version,
	    App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    'a longer pin than the report also refuses');
	my $refused = $gate->('9.1');
	$refused->_check_qemu_version;
	like(join("\n", @{ $refused->{log}{errors} }), qr/9\.0\.4.*9\.1/,
	    'and the message names both versions');

	# Output with no version in it fails closed
	open $fh, '>', $stub or die "Cannot write $stub: $!";
	print $fh "#!/bin/sh\n";
	print $fh "echo 'no version here'\n";
	close $fh;
	is($gate->('9.0')->_check_qemu_version,
	    App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    'output with no version in it refuses');

	# An absent binary fails closed
	my $empty = tempdir(CLEANUP => 1);
	local $ENV{PATH} = $empty;
	is($gate->('9.0')->_check_qemu_version,
	    App::FuguVM::Guest::EXIT_CONFIG_ERROR(),
	    'an absent binary refuses');
}

# The status report holds every key, for a stopped guest and for a
# guest with a record
{
	require App::FuguVM::State;

	my @keys = qw(accel arch bind_address console_port disk_exists
	    installed name pid proxy_url ssh_port state);

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'amd64',
		    ssh_port => 'auto', console_port => 'auto',
		    bind_address => '127.0.0.1',
		    cache_dir => "$root/cache" },
		state => $state,
	);

	my $status = $vm->status;
	for my $key (@keys) {
		ok(exists $status->{$key}, "a stopped guest reports $key");
	}
	is($status->{state}, 'stopped', 'the guest is stopped');
	is($status->{ssh_port}, undef, 'auto with no record has no port');
	is($status->{bind_address}, '127.0.0.1',
	    'status reports the bind address');
	is($status->{proxy_url}, undef,
	    'proxy_url is empty while the proxy does not run');

	$state->set_runtime(
	    accel => 'tcg', ssh_port => 2255, console_port => 4455);
	$state->vm_pidfile->write_pid($$);
	$status = $vm->status;
	for my $key (@keys) {
		ok(exists $status->{$key}, "a running guest reports $key");
	}
	is($status->{ssh_port}, 2255, 'status reports the recorded port');
	is($status->{console_port}, 4455, 'for both directives');
	is($status->{accel}, 'tcg', 'status reports the recorded accelerator');
	$state->clear_vm_pid;

	# status reports proxy_url from guest_url: the record of the
	# proxy plus a live child. This test process stands in for the
	# child.
	$state->store->set(proxy_port => 8123);
	$state->proxy_pidfile->write_pid($$);
	is($vm->status->{proxy_url}, 'http://10.0.2.2:8123',
	    'status reports proxy_url from guest_url');
	$state->proxy_pidfile->remove;
}

# The expect install carries the verify flag, as the word that the
# script reads by position
{
	my $on = App::FuguVM::Guest->new(
	    config => { name => 'default', arch => 'arm64' });
	my $config = $on->_install_config('secret', 'http://10.0.2.2:8080');
	is($config->{verify}, 'yes', 'verify defaults to yes');
	is($config->{root_password}, 'secret', 'the password rides along');
	is($config->{proxy_url}, 'http://10.0.2.2:8080', 'and the proxy URL');

	my $off = App::FuguVM::Guest->new(
	    config => { name => 'default', arch => 'arm64', verify => 0 });
	is($off->_install_config('secret', undef)->{verify}, 'no',
	    'verify 0 reads as the word no');
	is($off->_install_config('secret', undef)->{proxy_url}, 'none',
	    'and no proxy reads as none');
}

# up sets FUGUVM_DISTFILE_LIMIT from the configuration before it
# starts the proxy, so the spawned child inherits the cap
{
	require App::FuguVM::State;

	my $root = tempdir(CLEANUP => 1);
	my $state = App::FuguVM::State->new("$root/state", 'default');
	my $vm = App::FuguVM::Guest->new(
		config => { name => 'default', arch => 'arm64',
		    version => '7.8', cache_dir => "$root/cache",
		    distfile_cache => 4096 },
		state => $state,
		log   => TestLog->new,
	);

	# The stand-in start records the environment at spawn time and
	# starts nothing.
	my $seen;
	{
		no warnings 'redefine';
		local *Fugu::Proxy::start = sub ($self) {
			$seen = $ENV{FUGUVM_DISTFILE_LIMIT};
			return 8080;
		};
		local $ENV{FUGUVM_DISTFILE_LIMIT};
		ok(defined $vm->_ensure_proxy, '_ensure_proxy starts the proxy');
	}
	is($seen, 4096, 'the cap reaches the environment before the spawn');

	# The proxy cache of the guest carries the same cap
	is($vm->_proxy->cache->distfile_limit, 4096,
	    'the proxy cache of the guest carries the cap');

	# The mirror of the guest builds over the configured version
	# and architecture
	my $mirror = $vm->_mirror;
	is($mirror->url('miniroot78.img'),
	    'https://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/miniroot78.img',
	    '_mirror builds over the configured version and architecture');
}

done_testing();

# _flock_in_child($path):
#	Try a non-blocking exclusive flock on $path from a child
#	process. Return 1 when the child took the lock, and 0 when an
#	other holder refused it. The child exits through POSIX::_exit,
#	so it runs no END block of the test harness.
sub _flock_in_child ($path)
{
	require Fcntl;
	require POSIX;

	my $pid = fork // die "Cannot fork: $!";
	if ($pid == 0) {
		open my $fh, '>>', $path or POSIX::_exit(0);
		my $got =
		    flock($fh, Fcntl::LOCK_EX() | Fcntl::LOCK_NB()) ? 1 : 0;
		POSIX::_exit($got);
	}

	waitpid $pid, 0;
	return $? >> 8;
}

# Minimal log stub: it counts warnings for _bounded and keeps errors.
# Thus the tests can assert on diagnostics.
package TestLog;
sub new { return bless { warned => 0, errors => [] }, shift }
sub warning { my $self = shift; $self->{warned}++; return; }
sub info { return; }

sub error
{
	my ($self, $fmt, @args) = @_;
	push @{ $self->{errors} }, @args ? sprintf($fmt, @args) : $fmt;
	return;
}

sub debug { return; }
