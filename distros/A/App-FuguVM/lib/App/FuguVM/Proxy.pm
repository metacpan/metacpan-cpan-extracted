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

package App::FuguVM::Proxy;
our $VERSION = '0.1.1';

use Fugu::Log;
use Fugu::Proxy;

our @ISA = ('Fugu::Proxy');

# App::FuguVM::Proxy - the OpenBSD mirror policy over Fugu::Proxy.
#
# The generic proxy holds the serve loop, the cache and the metadata.
# This file holds only what is true of an OpenBSD mirror and of a QEMU
# guest: which URL is worth keeping, how to prune a release that is no
# longer in use, the address that the guest reaches the host by, and
# the port range.

# QEMU user-mode networking puts the host at this address. A guest
# that fetches through the proxy names it, and no other address
# reaches back out of the SLIRP network.
use constant HOST_GATEWAY => '10.0.2.2';

# $class->run_child($port, $cache_dir):
#	The entry point of the spawned child. The child builds its own
#	cache, warms the metadata, and serves until a SIGTERM.
sub run_child ( $class, $port, $cache_dir )
{
	my $log = Fugu::Log->new( mode => 'stderr', level => 'debug' );

	my $self = bless {
		cache => App::FuguVM::Proxy::Cache->new($cache_dir),
		meta  => Fugu::Proxy::Meta->new,
		log   => $log,
	}, $class;

	$log->info( 'Proxy starting on port %d', $port );
	$log->info( 'Cache directory: %s',       $cache_dir );

	$self->warm;

	return $self->serve($port);
}

# $self->guest_url:
#	Return the proxy URL as the guest reaches it, through the QEMU
#	gateway. The loopback address serves the same proxy, but a
#	guest cannot reach it.
sub guest_url ($self)
{
	my $port = $self->port;
	return if !defined $port;

	return 'http://' . HOST_GATEWAY . ":$port";
}

package App::FuguVM::Proxy::Cache;
our $VERSION = '0.1.1';

use Fugu::Log;
use Fugu::Proxy;

our @ISA = ('Fugu::Proxy::Cache');

# App::FuguVM::Proxy::Cache - which parts of an OpenBSD mirror to keep.
#
# The patterns are the release tree, the packages, the syspatch sets
# and the files that an installer reads. Every one of them is
# version-scoped, so nothing here outlives the release it belongs to.
# That is what makes prune safe.

my @CACHEABLE = (
	qr{/pub/OpenBSD/\d+\.\d+/\w+/.*\.(tgz|img|gz)$},    # File sets
	qr{/pub/OpenBSD/syspatch/.*\.tgz$},                 # Patches
	qr{/pub/OpenBSD/\d+\.\d+/packages/\w+/.*\.tgz$},    # Packages
	qr{/pub/OpenBSD/\d+\.\d+/\w+/SHA256(\.sig)?$},      # Checksums
	qr{/pub/OpenBSD/\d+\.\d+/\w+/miniroot\d+\.img$},    # Miniroot images
	qr{/pub/OpenBSD/\d+\.\d+/\w+/bsd(\.mp|\.rd)?$},     # Kernel files
	qr{/pub/OpenBSD/\d+\.\d+/\w+/BUILDINFO$},           # Build info
	qr{/pub/OpenBSD/\d+\.\d+/\w+/.*\.txt$},    # Text files (index, etc)
);

sub new ( $class, $cache_dir )
{
	return $class->SUPER::new(
		dir       => $cache_dir,
		cacheable => \&_is_openbsd_content,
		types     => {

			# A kernel has no extension, so the generic
			# table cannot name it
			qr{/bsd(\.mp|\.rd)?$} => 'application/octet-stream',
		},
	);
}

# _is_openbsd_content($url):
#	Report if the URL is part of an OpenBSD release tree.
sub _is_openbsd_content ($url)
{
	for my $pattern (@CACHEABLE) {
		return 1 if $url =~ $pattern;
	}

	return 0;
}

# $self->prune(@keep):
#	Remove the cached download tree of every OpenBSD version other
#	than @keep. The method returns [ { version, path, size } ] for
#	each removed tree.
#
#	Nothing else bounds this cache. 'fuguvm cache clear --stale'
#	prunes installed images. Those images live beside these
#	downloads under the same cache_dir, but no common key connects
#	them. Thus a version bump left the full file sets of the
#	previous version here for good. Nothing read them again,
#	because every pattern that is_cacheable admits is
#	version-scoped. And every copy of the directory that a
#	continuous-integration cache made still carried them.
#
#	The method removes whole directories, not matching files.
#	Removal of the files alone leaves the empty version tree
#	behind, and such a copy walks the tree.
#
#	The method does not touch a directory whose name is not a
#	version. In practice there are none. The patterns put
#	everything under pub/OpenBSD/<version>/ or
#	pub/OpenBSD/syspatch/<version>/. And a cache under $HOME is the
#	wrong place to delete on a guess.
sub prune ( $self, @keep )
{
	my $root = $self->root;
	return [] if !-d $root;

	my %keep = map { $_ => 1 } @keep;
	my @removed;

	for my $version_root ( $self->_version_roots ) {
		opendir my $dh, $version_root or next;
		my @versions = sort grep { /\A[0-9]+\.[0-9]+\z/ } readdir $dh;
		closedir $dh;

		for my $version (@versions) {
			next if $keep{$version};

			my $dir = "$version_root/$version";
			next if !-d $dir;

			# Measure the size before removal. Thus the caller
			# can say what the prune freed.
			my $size = $self->dir_size($dir);

			require File::Path;
			File::Path::remove_tree( $dir,
				{ error => \my $errors } );
			if ( $errors && @$errors ) {
				Fugu::Log->default->warning( 'Cannot remove %s',
					$dir );
				next;
			}

			push @removed,
			    {
				version => $version,
				path    => $dir,
				size    => $size,
			    };
		}
	}

	return \@removed;
}

# $self->_version_roots:
#	Return every directory whose immediate children are OpenBSD
#	version numbers, across all cached hosts. Release trees hang
#	off pub/OpenBSD. Syspatch sets sit one level deeper. Both have
#	the name of a version, and neither outlives it.
sub _version_roots ($self)
{
	my $root = $self->root;

	opendir my $dh, $root or return ();
	my @hosts = sort grep { !/\A\.\.?\z/ } readdir $dh;
	closedir $dh;

	my @roots;
	for my $host (@hosts) {
		my $release = "$root/$host/pub/OpenBSD";
		next if !-d $release;

		push @roots, $release;
		push @roots, "$release/syspatch" if -d "$release/syspatch";
	}

	return @roots;
}

1;
