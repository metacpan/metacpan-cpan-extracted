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

package App::FuguVM::Disk;
our $VERSION = '0.1.1';

use File::Basename;
use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use JSON::PP ();

sub new ( $class, $state_dir )
{
	my $self = bless { state_dir => $state_dir, }, $class;

	return $self;
}

# $self->create($name, $size, $backing_image):
#	Create the VM disk image. $size can be undef for an overlay.
#	The overlay then inherits the virtual size of $backing_image.
#	Every backing image is a qcow2: a cached base image or a
#	snapshot.
#
#	The method returns early when the path already exists. Thus
#	callers that replace a disk with an overlay must unlink the
#	disk first.
sub create ( $self, $name, $size = undef, $backing_image = undef )
{
	my $path = $self->path($name);

	Fugu::File->ensure_dir( dirname($path) ) or return;

	return $path if -f $path;    # Already exists

	my @cmd = ( 'qemu-img', 'create', '-f', 'qcow2' );

	if ( defined $backing_image ) {
		push @cmd, '-b', $backing_image, '-F', 'qcow2';
	}

	push @cmd, $path;
	push @cmd, $size if defined $size;

	# The capture also swallows the verbose "Formatting..." line of
	# qemu-img, which no caller wants to see
	my $result = Fugu::Process->run( cmd => \@cmd );

	unless ( $result->{success} ) {
		Fugu::Log->default->error( 'Failed to create disk image %s: %s',
			$path,
			$result->{stderr} || $result->{error} || 'unknown' );
		return;
	}

	return $path;
}

sub path ( $self, $name )
{
	return "$self->{state_dir}/$name/disk.qcow2";
}

# $self->info($name):
#	Get the qemu-img report on the disk as a hashref. The method
#	returns undef when there is no disk or when it cannot read the
#	disk. The inspection is read-only. Thus it asks for shared
#	access with -U. A running QEMU holds an exclusive lock. Without
#	shared access, the query fails on exactly the VMs whose backing
#	chain callers most need to resolve. If 'cache clear' skips the
#	disk of a running VM, it can remove the base from under that
#	VM.
sub info ( $self, $name )
{
	my $path = $self->path($name);
	return if !-f $path;

	# The inspection asks for shared access with -U, so it also
	# works against the disk of a running VM
	my $result = Fugu::Process->run(
		cmd => [ 'qemu-img', 'info', '-U', '--output=json', $path ] );
	return if !$result->{success};

	return eval { JSON::PP->new->utf8->decode( $result->{stdout} ) };
}

# $self->backing_file($name):
#	Get the absolute path of the image that backs the disk. The
#	method returns undef when the disk is standalone or when it
#	cannot inspect the disk. qemu-img reports a backing reference
#	even when the file it names is gone. This lets callers diagnose
#	a broken chain.
sub backing_file ( $self, $name )
{
	my $info = $self->info($name);
	return if !defined $info;

	my $backing = $info->{'full-backing-filename'}
	    // $info->{'backing-filename'};
	return if !defined $backing || $backing eq '';

	# Relative references resolve against the disk's own directory
	if ( $backing !~ m{^/} ) {
		$backing = dirname( $self->path($name) ) . "/$backing";
	}

	return $backing;
}

# P5: Check the disk image integrity. The method returns a hashref
# with the 'status' and 'output' keys. The 'status' key is 'ok' or
# 'corrupted'.
sub check ( $self, $name )
{
	my $path = $self->path($name);
	return if !-f $path;

	my $result =
	    Fugu::Process->run( cmd => [ 'qemu-img', 'check', $path ] );
	my $output = $result->{stdout} . $result->{stderr};

	return {
		status => $result->{success} ? 'ok' : 'corrupted',
		output => $output,
		path   => $path,
	};
}

# P5: Repair the disk image. The method returns true on success and
# false on failure.
sub repair ( $self, $name )
{
	my $path = $self->path($name);
	return 0 if !-f $path;

	# Run qemu-img check with the repair option
	my $result = Fugu::Process->run(
		cmd => [ 'qemu-img', 'check', '-r', 'all', $path ] );

	return $result->{success} ? 1 : 0;
}

1;
