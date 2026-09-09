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
our $VERSION = '0.2.0';

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
#
#	The spawn passes a fixed argument list, so the distfile cap
#	reaches the child through the environment, which it inherits
#	from fuguvm. An absent variable means 0, and 0 turns the
#	distfile cache off.
sub run_child ( $class, $port, $cache_dir )
{
	my $log = Fugu::Log->new( mode => 'stderr', level => 'debug' );

	my $limit = $ENV{FUGUVM_DISTFILE_LIMIT} // 0;
	$limit = 0 if $limit !~ /\A[0-9]+\z/;

	my $self = bless {
		cache => App::FuguVM::Proxy::Cache->new( $cache_dir, $limit ),
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
#	guest cannot reach it. The method returns undef while the
#	proxy does not run: a port that a crash left behind is not a
#	reachable proxy.
sub guest_url ($self)
{
	return if !$self->is_running;

	my $port = $self->port;
	return if !defined $port;

	return 'http://' . HOST_GATEWAY . ":$port";
}

package App::FuguVM::Proxy::Cache;
our $VERSION = '0.2.0';

use Fugu::Log;
use Fugu::Proxy;

our @ISA = ('Fugu::Proxy::Cache');

# App::FuguVM::Proxy::Cache - which parts of an OpenBSD mirror to keep.
#
# The patterns are the release tree, the packages, the syspatch sets,
# the source tarballs and the files that an installer reads. Every one
# of them is version-scoped, so nothing here outlives the release it
# belongs to. That is what makes prune safe.
#
# The distfile tree is the one exception: a distfile belongs to a
# port and not to a release, so no version scopes it and prune leaves
# it. The distfile cap of trim_distfiles is its bound instead, and
# the tree is cacheable only while the cap is above zero.

my @CACHEABLE = (
	qr{/pub/OpenBSD/\d+\.\d+/\w+/.*\.(tgz|img|gz)$},    # File sets
	qr{/pub/OpenBSD/syspatch/.*\.tgz$},                 # Patches
	qr{/pub/OpenBSD/\d+\.\d+/packages/\w+/.*\.tgz$},    # Packages
	qr{/pub/OpenBSD/\d+\.\d+/\w+/SHA256(\.sig)?$},      # Checksums
	qr{/pub/OpenBSD/\d+\.\d+/\w+/miniroot\d+\.img$},    # Miniroot images
	qr{/pub/OpenBSD/\d+\.\d+/\w+/bsd(\.mp|\.rd)?$},     # Kernel files
	qr{/pub/OpenBSD/\d+\.\d+/\w+/BUILDINFO$},           # Build info
	qr{/pub/OpenBSD/\d+\.\d+/\w+/.*\.txt$},    # Text files (index, etc)

	# The source tarballs of a release, by name. A wildcard at the
	# version level would admit any file that a mirror puts there.
	qr{/pub/OpenBSD/\d+\.\d+/(ports|src|sys|xenocara)\.tar\.gz$},

	# The manifest of the version directory, which signs the four
	# source tarballs.
	qr{/pub/OpenBSD/\d+\.\d+/SHA256(\.sig)?$},
);

# The distfile pattern is conditional on the cap. It requires a file
# name at the end, so a directory listing with a trailing solidus
# stays outside the cache. It filters no extension, because a
# distfile carries every extension and sometimes none.
my $DISTFILE = qr{/pub/OpenBSD/distfiles/(?:[^/]+/)*[^/]+$};

# $class->new($cache_dir, $limit):
#	Build the cache. The optional limit is the distfile cap in
#	bytes, and 0 turns the distfile cache off.
sub new ( $class, $cache_dir, $limit = 0 )
{
	my $self = $class->SUPER::new(
		dir       => $cache_dir,
		cacheable => sub ($url) { _is_openbsd_content( $url, $limit ) },
		types     => {

			# A kernel has no extension, so the generic
			# table cannot name it
			qr{/bsd(\.mp|\.rd)?$} => 'application/octet-stream',
		},
	);
	$self->{distfile_limit} = $limit;

	return $self;
}

# _is_openbsd_content($url, $limit):
#	Report if the URL is part of an OpenBSD release tree, or a
#	distfile while the cap is above zero. A cache that grows with
#	no bound in a home directory is the failure that the default
#	of 0 avoids.
sub _is_openbsd_content ( $url, $limit = 0 )
{
	for my $pattern (@CACHEABLE) {
		return 1 if $url =~ $pattern;
	}

	return 1 if $limit > 0 && $url =~ $DISTFILE;

	return 0;
}

# $self->store($url, $content):
#	Store one response body, and hold the distfile tree under the
#	cap after a distfile store. A set store must not walk the
#	distfile tree.
sub store ( $self, $url, $content )
{
	my $path = $self->SUPER::store( $url, $content );
	return if !defined $path;

	$self->trim_distfiles if $url =~ $DISTFILE;

	return $path;
}

# $self->distfile_limit:
#	Return the distfile cap in bytes.
sub distfile_limit ($self)
{
	return $self->{distfile_limit};
}

# $self->distfile_size:
#	Return the bytes of the distfile tree, over every cached host.
sub distfile_size ($self)
{
	my $total = 0;
	$total += $self->dir_size($_) for $self->_distfile_roots;

	return $total;
}

# $self->trim_distfiles:
#	Hold the distfile tree under the cap. The eviction removes the
#	oldest file first, by modification time. The modification time
#	is the store time of the file, because store writes each file
#	one time; the access time is not usable, because a host can
#	mount its home directory with noatime. A cap of 0 removes the
#	whole tree, because the operator turned the cache off. The
#	method removes files and leaves the directories, because a
#	later fetch refills them. It returns the removed files as
#	[ { path, size } ].
sub trim_distfiles ($self)
{
	my @files;
	for my $root ( $self->_distfile_roots ) {
		$self->walk(
			$root,
			sub ($path) {
				my @stat = stat $path;
				return if !@stat;
				push @files,
				    {
					path  => $path,
					size  => $stat[7],
					mtime => $stat[9],
				    };
			} );
	}

	my $total = 0;
	$total += $_->{size} for @files;

	my @removed;
	for my $file ( sort { $a->{mtime} <=> $b->{mtime} } @files ) {
		last if $total <= $self->{distfile_limit};

		unlink $file->{path} or do {
			Fugu::Log->default->warning( 'Cannot remove %s',
				$file->{path} );
			next;
		};

		$total -= $file->{size};
		push @removed, { path => $file->{path}, size => $file->{size} };
	}

	return \@removed;
}

# $self->_distfile_roots:
#	Return the distfile tree of each cached host that holds one.
sub _distfile_roots ($self)
{
	my $root = $self->root;

	opendir my $dh, $root or return ();
	my @hosts = sort grep { !/\A\.\.?\z/ } readdir $dh;
	closedir $dh;

	return grep { -d $_ }
	    map { "$root/$_/pub/OpenBSD/distfiles" } @hosts;
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
