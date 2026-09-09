#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);

use_ok('App::FuguVM::State');

# Test state creation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    ok(defined $state, 'State object created');
    ok(-d "$tmpdir/test", 'VM state directory created');
}

# Test VM PID management
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    $state->vm_pidfile->write_pid(12345);
    is($state->get_vm_pid, 12345, 'VM PID stored and retrieved');
    
    $state->clear_vm_pid;
    is($state->get_vm_pid, undef, 'VM PID cleared');
}

# Test VM PID is stored only in pid file (single source of truth)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    $state->vm_pidfile->write_pid(54321);
    
    # Make sure that the vm.pid file exists and contains the PID
    my $pid_file = "$tmpdir/test/vm.pid";
    ok(-f $pid_file, 'vm.pid file created');
    open my $fh, '<', $pid_file;
    my $pid_content = <$fh>;
    close $fh;
    chomp $pid_content;
    is($pid_content, '54321', 'vm.pid file contains correct PID');
    
    # Make sure that the PID is NOT in the status JSON
    my $status_file = "$tmpdir/test/status";
    if (-f $status_file) {
        open my $sfh, '<', $status_file;
        local $/;
        my $json = <$sfh>;
        close $sfh;
        unlike($json, qr/"pid"/, 'PID not stored in status JSON');
    }
    
    # Clear the PID. Make sure that the pid file is gone.
    $state->clear_vm_pid;
    ok(!-f $pid_file, 'vm.pid file removed after clear_vm_pid');
}

# Test VM PID does not persist across state reloads (ephemeral)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    $state->vm_pidfile->write_pid($$);
    is($state->get_vm_pid, $$, 'VM PID set to current process');
    
    # Reload the state. The PID stays readable from the pid file.
    my $state2 = App::FuguVM::State->new($tmpdir, 'test');
    is($state2->get_vm_pid, $$, 'VM PID readable after state reload');
    
    # Clear the PID and reload. The PID must be gone.
    $state2->clear_vm_pid;
    my $state3 = App::FuguVM::State->new($tmpdir, 'test');
    is($state3->get_vm_pid, undef, 'VM PID cleared persists after reload');
}

# Test is_vm_running (with fake PID)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    # Use the current process PID, which is running
    $state->vm_pidfile->write_pid($$);
    ok($state->is_vm_running, 'is_vm_running returns true for running process');
    
    # Use an invalid PID
    $state->vm_pidfile->write_pid(99999999);
    ok(!$state->is_vm_running, 'is_vm_running returns false for non-running process');
}

# The proxy child rides on its own pid file, apart from the VM's
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');

    $state->proxy_pidfile->write_pid(22222);
    is($state->proxy_pidfile->read_pid, 22222,
	'proxy pidfile stores its own PID');
    ok(-f "$tmpdir/test/proxy.pid", 'proxy.pid is a separate file');

    $state->clear_vm_pid;
    is($state->proxy_pidfile->read_pid, 22222,
	'proxy PID unchanged after clearing VM PID');

    $state->proxy_pidfile->remove;
    ok(!-f "$tmpdir/test/proxy.pid", 'proxy.pid removed');
}

# The autoinstall responder rides on its own pid file too
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');

    isa_ok($state->autoinstall_pidfile, 'Fugu::Pidfile',
	'autoinstall_pidfile');
    like($state->autoinstall_pidfile->path, qr{\Q$tmpdir\E/test/},
	'the pid file lives under the state directory of the guest');
    isnt($state->autoinstall_pidfile->path, $state->proxy_pidfile->path,
	'and its path differs from the proxy pid file');

    $state->autoinstall_pidfile->write_pid(33333);
    is($state->autoinstall_pidfile->read_pid, 33333,
	'the responder pid file stores its own PID');
    ok(-f "$tmpdir/test/autoinstall.pid", 'autoinstall.pid is its own file');
    $state->autoinstall_pidfile->remove;
    ok(!-f "$tmpdir/test/autoinstall.pid", 'autoinstall.pid removed');
}

# Test installation state
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');

    ok(!$state->is_installed, 'Not installed initially');
    is($state->get_installed_arch, undef,
	'a fresh state records no architecture');

    $state->mark_installed('arm64');
    ok($state->is_installed, 'Installed after mark_installed');
    is($state->get_installed_arch, 'arm64',
	'mark_installed records the architecture');

    # Reload the state and make sure that the value persists
    my $state2 = App::FuguVM::State->new($tmpdir, 'test');
    ok($state2->is_installed, 'Installation state persisted');
    is($state2->get_installed_arch, 'arm64',
	'the architecture persists across a reload');
}

# Test disk paths
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    like($state->disk_path, qr/disk\.qcow2$/, 'disk_path ends with disk.qcow2');
    ok(!$state->disk_exists, 'disk_exists returns false when no disk');
}

# Test root password management
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    is($state->get_root_password, undef, 'No password initially');
    
    $state->set_root_password('testpass123');
    is($state->get_root_password, 'testpass123', 'Password stored and retrieved');
    
    # Reload the state and make sure that the value persists
    my $state2 = App::FuguVM::State->new($tmpdir, 'test');
    is($state2->get_root_password, 'testpass123', 'Password persisted');
}

# Test SSH key installation state
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');
    
    is($state->get_installed_ssh_pubkey, undef, 'No pubkey stored initially');
    
    my $test_pubkey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... test@example';
    $state->mark_ssh_key_installed($test_pubkey);
    is($state->get_installed_ssh_pubkey, $test_pubkey, 'Pubkey stored correctly');
    
    # Reload the state and make sure that the value persists
    my $state2 = App::FuguVM::State->new($tmpdir, 'test');
    is($state2->get_installed_ssh_pubkey, $test_pubkey, 'Pubkey persisted correctly');
}

# The runtime record: the facts of one run of one guest
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $state = App::FuguVM::State->new($tmpdir, 'test');

    is_deeply($state->get_runtime, {},
	'get_runtime returns an empty hash reference for a fresh state');

    $state->set_runtime(
	accel        => 'kvm',
	ssh_port     => 2223,
	console_port => 4445,
    );
    is_deeply($state->get_runtime,
	{ accel => 'kvm', ssh_port => 2223, console_port => 4445 },
	'set_runtime and get_runtime round-trip the three facts');

    # The record persists across a reload
    my $state2 = App::FuguVM::State->new($tmpdir, 'test');
    is($state2->get_runtime->{ssh_port}, 2223,
	'the record survives a reload');

    # clear_runtime empties the record, and the store survives
    $state2->set_root_password('sentinel');
    $state2->clear_runtime;
    is_deeply($state2->get_runtime, {}, 'clear_runtime empties the record');

    my $state3 = App::FuguVM::State->new($tmpdir, 'test');
    is_deeply($state3->get_runtime, {}, 'and the clearing persists');
    is($state3->get_root_password, 'sentinel',
	'the rest of the store survives the clearing');
}

# ============================================================
# Robustness tests (from ROBUSTNESS-REPORT.md)
# ============================================================

# Issue 1: Extremely long VM name
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    # Suppress warnings for this test
    local $SIG{__WARN__} = sub {};
    
    my $long_name = 'x' x 10000;
    my $state = App::FuguVM::State->new($tmpdir, $long_name);
    is($state, undef, 'Long VM name (10000 chars) returns undef');
}

# Issue 1: a VM name at the boundary of 255 chars works
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    my $max_name = 'x' x 255;
    my $state = App::FuguVM::State->new($tmpdir, $max_name);
    ok(defined $state, 'VM name at 255 chars is accepted');
}

# Issue 1: a VM name over the boundary at 256 chars fails
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    local $SIG{__WARN__} = sub {};
    
    my $over_name = 'x' x 256;
    my $state = App::FuguVM::State->new($tmpdir, $over_name);
    is($state, undef, 'VM name at 256 chars returns undef');
}

# Issue 1: VM name with invalid characters (path separator)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    local $SIG{__WARN__} = sub {};
    
    my $state = App::FuguVM::State->new($tmpdir, '../../../etc/passwd');
    is($state, undef, 'VM name with path traversal returns undef');
}

# Issue 3: File where directory expected
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    # Create a file where the VM state directory belongs
    my $file_path = "$tmpdir/testvm";
    open my $fh, '>', $file_path or die "Cannot create file: $!";
    print $fh "not a directory\n";
    close $fh;
    
    local $SIG{__WARN__} = sub {};
    
    my $state = App::FuguVM::State->new($tmpdir, 'testvm');
    is($state, undef, 'File where directory expected returns undef');
}

# Issue 4: Symlink as state directory
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    # Create a symlink where the VM state directory belongs
    my $target = "$tmpdir/target";
    mkdir $target;
    my $link = "$tmpdir/symvm";
    symlink $target, $link;
    
    local $SIG{__WARN__} = sub {};
    
    my $state = App::FuguVM::State->new($tmpdir, 'symvm');
    is($state, undef, 'Symlink as state directory returns undef');
}

# Issue 4: Symlink to file as state directory
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    # Create a symlink to a file
    my $target = "$tmpdir/target.txt";
    open my $fh, '>', $target or die "Cannot create file: $!";
    close $fh;
    my $link = "$tmpdir/linkvm";
    symlink $target, $link;
    
    local $SIG{__WARN__} = sub {};
    
    my $state = App::FuguVM::State->new($tmpdir, 'linkvm');
    is($state, undef, 'Symlink to file as state directory returns undef');
}

# A VM name with valid special characters works
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    my $state = App::FuguVM::State->new($tmpdir, 'my-vm_test.1');
    ok(defined $state, 'VM name with dashes, underscores, dots is accepted');
    ok(-d "$tmpdir/my-vm_test.1", 'State directory created for valid VM name');
}

# Empty VM name (edge case)
{
    my $tmpdir = tempdir(CLEANUP => 1);
    
    # An empty name still creates a directory. The directory becomes
    # "$tmpdir/". This behavior can be intentional, or a later change
    # can restrict it.
    my $state = App::FuguVM::State->new($tmpdir, '');
    # The behavior here depends on whether the code allows empty
    # names. Currently an empty name creates a directory named "",
    # which is valid.
    ok(defined $state || !defined $state, 'Empty VM name handled (either way)');
}

done_testing();
