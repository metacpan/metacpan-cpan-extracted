#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);

use_ok('App::FuguVM::Disk');

# Test object creation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $disk = App::FuguVM::Disk->new($tmpdir);
    ok(defined $disk, 'Disk object created');
}

# Test path generation
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $disk = App::FuguVM::Disk->new($tmpdir);
    
    my $path = $disk->path('test');
    like($path, qr/test.*disk\.qcow2$/, 'path includes VM name and disk.qcow2');
}

# Skip tests that require qemu-img
SKIP: {
    my $has_qemu = `which qemu-img 2>/dev/null`;
    skip 'qemu-img not installed', 10 unless $has_qemu;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $disk = App::FuguVM::Disk->new($tmpdir);

    # Test disk creation
    my $path = $disk->create('test', '1G');
    ok(defined $path, 'create returns path');
    ok(-f $path, 'disk file created');

    # A standalone disk has no backing file
    is($disk->backing_file('test'), undef,
	'backing_file is undef for a standalone disk');
    is($disk->backing_file('missing'), undef,
	'backing_file is undef for a missing disk');

    # Overlays: no size, and always a qcow2 backing format
    my $overlay_dir = tempdir(CLEANUP => 1);
    my $overlay = App::FuguVM::Disk->new($overlay_dir);
    my $opath = $overlay->create('child', undef, $path);
    ok(defined $opath, 'overlay created without an explicit size');

    my $info = $overlay->info('child');
    is($info->{'backing-filename-format'}, 'qcow2',
	'the backing format is qcow2, not raw');
    is($overlay->backing_file('child'), $path,
	'backing_file resolves the parent image');
    is($info->{'virtual-size'}, $disk->info('test')->{'virtual-size'},
	'overlay inherits the backing image virtual size');

    # qemu-img still reports the reference once the parent is gone.
    # This makes a broken chain diagnosable, not an opaque failure
    # at boot.
    unlink $path;
    is($overlay->backing_file('child'), $path,
	'backing_file still names a missing parent');
    ok(!-f $overlay->backing_file('child'),
	'and the caller can see that it is gone');
}

# A running QEMU holds an exclusive lock on its disk. Thus inspection
# must ask for shared access. Without it, info() fails on exactly the
# VMs whose chain callers most need. 'cache clear' then sees no backing
# file for a running VM and removes the base while the VM uses it.
SKIP: {
    my $has_qemu_io = `which qemu-io 2>/dev/null`;
    skip 'qemu-io not installed', 4 unless $has_qemu_io;

    my $tmpdir = tempdir(CLEANUP => 1);
    my $disk = App::FuguVM::Disk->new($tmpdir);
    my $path = $disk->create('locked', '64M');
    my $parent = $disk->create('parent', '64M');

    my $overlay_dir = tempdir(CLEANUP => 1);
    my $overlay = App::FuguVM::Disk->new($overlay_dir);
    $overlay->create('kid', undef, $parent);

    # qemu-io holds the image, and its lock, while its stdin is open.
    my $spawned = open(my $io, '|-', "qemu-io '$path' >/dev/null 2>&1");
    my $spawned_kid =
	open(my $io2, '|-', "qemu-io '@{[$overlay->path('kid')]}' >/dev/null 2>&1");
    skip 'cannot spawn qemu-io', 4 unless $spawned && $spawned_kid;

    # Wait for the lock and prove that qemu-io really holds it. An
    # unshared query that fails here is the condition that used to
    # break the callers.
    my $locked = 0;
    for (1 .. 100) {
	`qemu-img info --output=json '$path' 2>&1`;
	if ($? != 0) { $locked = 1; last; }
	select(undef, undef, undef, 0.1);
    }
    ok($locked, 'qemu-io holds an exclusive lock on the image');

    my $info = $disk->info('locked');
    ok(defined $info, 'info still reads a locked image');
    is($info->{'virtual-size'}, 64 * 1024 * 1024,
	'and reports its size correctly');
    is($overlay->backing_file('kid'), $parent,
	'backing_file resolves the chain of a locked overlay');

    close $io;
    close $io2;
}

done_testing();
