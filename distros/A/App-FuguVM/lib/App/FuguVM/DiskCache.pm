# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@dickolsson.com>
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

# App::FuguVM::DiskCache - cache of installed OpenBSD disks.
#
# An OpenBSD installation under TCG emulation costs tens of minutes.
# This module keeps the result: a pristine, compacted copy of the disk,
# taken the moment the installer finished. Later runs use that copy as
# the backing image of a throwaway overlay.
#
# The module caches the disk. App::FuguVM::Miniroot caches the install
# media that produced it. Neither is a cache of the other.

package App::FuguVM::DiskCache;
our $VERSION = '0.1.1';

use Digest::SHA ();
use File::Path  qw(remove_tree);
use Fugu::File;
use Fugu::Log;
use Fugu::Proxy;
use App::FuguVM::Console;
use App::FuguVM::Miniroot;

use constant {
	BASE_NAME         => 'base.qcow2',
	META_NAME         => 'meta.json',
	INSTALLED_DIR     => 'installed',
	SNAPSHOT_DIR      => 'snapshots',
	TEMP_PREFIX       => '.tmp.',
	GENERATION_FILE   => 'cache-generation',
	INSTALL_SCRIPT    => 'install.exp',
	KEY_HASH_LENGTH   => 8,
	MAX_SNAPSHOT_NAME => 128,
};

sub new ( $class, $cache_dir )
{
	my $self =
	    bless { cache_dir => Fugu::File->expand_tilde($cache_dir), },
	    $class;

	return $self;
}

# $self->installed_dir:
#	Return the directory that holds every cached entry.
sub installed_dir ($self)
{
	return "$self->{cache_dir}/" . INSTALLED_DIR;
}

# $self->entry_dir($key):
#	Return the directory of one cached entry.
sub entry_dir ( $self, $key )
{
	return $self->installed_dir . "/$key";
}

# $self->base_path($key):
#	Return the absolute path of the base image of an entry. The
#	method does not check that the image exists.
sub base_path ( $self, $key )
{
	return $self->entry_dir($key) . '/' . BASE_NAME;
}

# $self->key($vm_config):
#	Derive the cache key for a VM configuration:
#	<version>-<arch>-<hash8>. The hash covers everything that
#	shapes an installed disk: the OpenBSD version, the
#	architecture, the disk size, the installer script, and the
#	generation counter. It covers nothing else. Thus memory and
#	port changes keep hitting the same entry. Return undef when an
#	input cannot be read. Then the caller has no key and thus no
#	caching.
sub key ( $self, $vm_config )
{
	my $version   = _sanitize( $vm_config->{version} // '' );
	my $arch      = _sanitize(App::FuguVM::Miniroot::ARCH);
	my $disk_size = $vm_config->{disk_size} // '';

	my $script = $self->_install_script;
	if ( !defined $script ) {
		warn "Cannot locate " . INSTALL_SCRIPT . " for cache key\n";
		return;
	}

	my $installer = Fugu::File->read($script);
	return if !defined $installer;

	my $generation_file = $self->_generation_file;
	if ( !defined $generation_file ) {
		warn "Cannot locate " . GENERATION_FILE . " for cache key\n";
		return;
	}

	my $generation = Fugu::File->read($generation_file);
	return if !defined $generation;

	# Hash the file contents separately. Thus the joined record
	# stays free of newlines, and an input value cannot forge the
	# delimiter.
	my @inputs = (
		"version=$version",
		"arch=$arch",
		"disk_size=$disk_size",
		'install=' . Digest::SHA::sha256_hex($installer),
		'generation=' . Digest::SHA::sha256_hex($generation),
	);

	my $hash = Digest::SHA::sha256_hex( join( "\n", @inputs ) );

	return "$version-$arch-" . substr( $hash, 0, KEY_HASH_LENGTH );
}

# $self->lookup($key):
#	Return { base => path, meta => hashref, dir => path } for a
#	complete entry, or undef otherwise. A half-written entry is a
#	miss, not an error. The caller falls back to a full
#	installation.
sub lookup ( $self, $key )
{
	return if !defined $key;

	my $dir  = $self->entry_dir($key);
	my $base = "$dir/" . BASE_NAME;
	return if !-f $base;

	my $meta = Fugu::File->read_json( "$dir/" . META_NAME );
	return if !defined $meta;

	return {
		key  => $key,
		dir  => $dir,
		base => $base,
		meta => $meta,
	};
}

# $self->store($key, $disk_path, $meta):
#	Publish $disk_path as the cached base image for $key. The
#	method builds the entry whole in a sibling temporary directory.
#	Then it publishes the entry with a rename of that directory.
#	Thus no reader sees the base image of one installation beside
#	the metadata of another installation. Such a mismatch would
#	look live. It would then wedge every later boot with a root
#	password that does not open the image.
#
#	Entries are write-once: a rename onto a populated directory
#	fails with ENOTEMPTY, and the existing entry wins. Return the
#	base image path, or undef on any failure.
sub store ( $self, $key, $disk_path, $meta = {} )
{
	return if !defined $key;

	if ( !-f $disk_path ) {
		warn "Cannot cache missing disk image: $disk_path\n";
		return;
	}

	Fugu::File->ensure_dir( $self->installed_dir ) or return;

	my $target = $self->entry_dir($key);
	if ( -e "$target/" . BASE_NAME ) {
		Fugu::Log->default->warning(
			'Image cache entry already exists: %s', $key );
		return;
	}

	my $built = Fugu::File->atomic_dir(
		$target,
		sub ($tmp) {
			my $base = "$tmp/" . BASE_NAME;
			return 0 if !_convert( $disk_path, $base );

			chmod 0400, $base or do {
				Fugu::Log->default->warning(
					'Cannot set permissions on %s: %s',
					$base, $! );
				return 0;
			};

			my %record = (
				%$meta,
				key        => $key,
				created_at => time,
			);

			# The record carries the guest root password, so
			# the file gets its mode before its content
			return Fugu::File->write_json( "$tmp/" . META_NAME,
				\%record, mode => 0600 ) ? 1 : 0;
		} );
	return if !defined $built;

	return "$target/" . BASE_NAME;
}

# $self->list:
#	Return every complete entry, newest first, as
#	{ key, dir, base, size, created_at, meta, snapshots }
sub list ($self)
{
	my @entries;
	my $installed = $self->installed_dir;
	return \@entries if !-d $installed;

	opendir my $dh, $installed or return \@entries;
	my @keys = grep { !/^\./ && -d "$installed/$_" } readdir $dh;
	closedir $dh;

	for my $key ( sort @keys ) {
		my $entry = $self->lookup($key) or next;
		$entry->{size} = Fugu::Proxy::Cache->dir_size( $entry->{dir} );
		$entry->{created_at} = $entry->{meta}{created_at};
		$entry->{snapshots}  = $self->_snapshot_names($key);
		push @entries, $entry;
	}

	return [
		sort { ( $b->{created_at} // 0 ) <=> ( $a->{created_at} // 0 ) }
		    @entries
	];
}

# $self->key_for_path($path):
#	Return the cache key whose entry contains $path. The path can
#	point to a base image or to a snapshot. Return undef when $path
#	lies outside the cache. The method lets a caller answer "which
#	cached image is this disk built on?".
sub key_for_path ( $self, $path )
{
	return if !defined $path;

	my $installed = $self->installed_dir . '/';
	return if index( $path, $installed ) != 0;

	my ($key) = split m{/}, substr( $path, length $installed ), 2;
	return if !defined $key || $key eq '';

	return $key;
}

# $self->snapshot_dir($key):
#	Return the directory that holds the named snapshot layers of
#	an entry.
sub snapshot_dir ( $self, $key )
{
	return $self->entry_dir($key) . '/' . SNAPSHOT_DIR;
}

# $self->snapshot_path($key, $name):
#	Return the absolute path of a named snapshot. The method does
#	not check that the snapshot exists.
sub snapshot_path ( $self, $key, $name )
{
	return $self->snapshot_dir($key) . "/$name.qcow2";
}

# valid_snapshot_name($name):
#	Snapshot names become file names inside the cache. Thus they
#	obey the same restrictions as VM names, plus a leading
#	alphanumeric. The leading alphanumeric keeps them clear of the
#	dot-files of the cache.
sub valid_snapshot_name ( $, $name )
{
	return 0 if !Fugu::File->valid_name($name);
	return 0 if length($name) > MAX_SNAPSHOT_NAME;
	return 0 if $name !~ /^[A-Za-z0-9][\w.-]*$/;

	return 1;
}

# $self->snapshot_store($key, $name, $disk_path, $meta):
#	Publish the stopped working disk as the named snapshot layer of
#	entry $key.
#
#	The method flattens the disk onto base.qcow2 and does not copy
#	it. A copy would carry the backing-file header of the working
#	disk verbatim. That header is only correct while the disk hangs
#	directly off the base. After a restore the disk hangs off a
#	snapshot. Thus a copy would stack chains without bound. A
#	normal second run saves the same name again. Then a copy would
#	name itself as its own backing file. The flatten operation also
#	keeps every snapshot a direct child of the base. Thus no
#	snapshot is the parent of another snapshot, and the removal of
#	one snapshot cannot orphan another.
#
#	Return the snapshot path, or undef on failure.
sub snapshot_store ( $self, $key, $name, $disk_path, $meta = {} )
{
	if ( !$self->valid_snapshot_name($name) ) {
		warn "Invalid snapshot name: " . ( $name // '(undef)' ) . "\n";
		return;
	}

	my $entry = $self->lookup($key);
	if ( !defined $entry ) {
		warn "No cached image for $key to snapshot against\n";
		return;
	}

	if ( !-f $disk_path ) {
		warn "Cannot snapshot missing disk image: $disk_path\n";
		return;
	}

	my $dir = $self->snapshot_dir($key);
	Fugu::File->ensure_dir($dir) or return;

	# qemu-img writes the image, so the atomic file helpers cannot
	# carry it. It goes through one temporary path and one rename.
	my $target   = $self->snapshot_path( $key, $name );
	my $tmp_disk = "$target." . TEMP_PREFIX . $$;

	unlink $tmp_disk;

	if ( !_convert( $disk_path, $tmp_disk, $entry->{base} ) ) {
		unlink $tmp_disk;
		return;
	}

	chmod 0400, $tmp_disk or do {
		warn "Cannot set permissions on $tmp_disk: $!\n";
		unlink $tmp_disk;
		return;
	};

	# The root password belongs to the base image. Thus the method
	# copies it from there and does not trust the caller.
	my %record = (
		%$meta,
		key           => $key,
		name          => $name,
		root_password => $entry->{meta}{root_password},
		created_at    => time,
	);

	# Metadata first, atomically, with the mode before the content.
	# To save a name again is normal. A reader that catches the
	# window sees the previous image with the new metadata. Those
	# fields describe the base, which did not change.
	if (
		!Fugu::File->write_json(
			"$dir/$name.json", \%record, mode => 0600
		) )
	{
		unlink $tmp_disk;
		return;
	}
	if ( !rename $tmp_disk, $target ) {
		warn "Cannot publish snapshot $name: $!\n";
		unlink $tmp_disk;
		return;
	}

	return $target;
}

# $self->snapshot_lookup($key, $name):
#	Return { key, name, path, meta } for a snapshot whose image,
#	metadata, and backing chain all resolve. Return undef
#	otherwise. A snapshot whose base was removed is a miss. Thus a
#	caller can fall back to a provision from scratch and does not
#	fail hard.
sub snapshot_lookup ( $self, $key, $name )
{
	return if !$self->valid_snapshot_name($name);

	my $path = $self->snapshot_path( $key, $name );
	return if !-f $path;

	my $meta =
	    Fugu::File->read_json( $self->snapshot_dir($key) . "/$name.json" );
	return if !defined $meta;

	my $base = $self->base_path($key);
	return if !-f $base;

	return {
		key  => $key,
		name => $name,
		path => $path,
		base => $base,
		meta => $meta,
	};
}

# $self->snapshot_list($key):
#	Return the sorted snapshots of an entry, as
#	{ name, path, size, created_at }
sub snapshot_list ( $self, $key )
{
	my @snapshots;

	for my $name ( @{ $self->_snapshot_names($key) } ) {
		my $found = $self->snapshot_lookup( $key, $name ) or next;
		push @snapshots,
		    {
			name       => $name,
			path       => $found->{path},
			size       => ( -s $found->{path} ) // 0,
			created_at => $found->{meta}{created_at},
			meta       => $found->{meta},
		    };
	}

	return \@snapshots;
}

# $self->snapshot_remove($key, $name):
#	Delete a snapshot and its metadata. Removal is safe in any
#	order: snapshots are always direct children of the base, never
#	of each other.
sub snapshot_remove ( $self, $key, $name )
{
	return 0 if !$self->valid_snapshot_name($name);

	my $dir  = $self->snapshot_dir($key);
	my $path = "$dir/$name.qcow2";
	my $meta = "$dir/$name.json";

	for my $file ( $path, $meta ) {
		next if !-e $file;
		unlink $file or do {
			warn "Cannot remove $file: $!\n";
			return 0;
		};
	}

	return 1;
}

# $self->_snapshot_names($key):
#	Return the sorted names of the named snapshot layers under an
#	entry.
sub _snapshot_names ( $self, $key )
{
	my $dir = $self->snapshot_dir($key);
	return [] if !-d $dir;

	opendir my $dh, $dir or return [];
	my @names;
	for my $file ( readdir $dh ) {
		next if $file !~ /^([^.][^\/]*)\.qcow2$/;
		push @names, $1;
	}
	closedir $dh;

	return [ sort @names ];
}

# $self->remove($key):
#	Delete a cached entry and everything under it. Return true when
#	the entry is gone afterwards.
sub remove ( $self, $key )
{
	my $dir = $self->entry_dir($key);
	return 1 if !-d $dir;

	remove_tree( $dir, { safe => 0 } );
	if ( -e $dir ) {
		warn "Cannot remove image cache entry $key\n";
		return 0;
	}

	return 1;
}

# $self->sweep_temp:
#	Remove the temporary entry trees that an interrupted store left
#	behind. This includes trees from earlier processes. Return the
#	count of removed trees.
sub sweep_temp ($self)
{
	return Fugu::File->sweep_temp( $self->installed_dir );
}

# _convert($source, $target, $backing):
#	Compact $source into a fresh qcow2 at $target. When $backing is
#	given, keep it as the parent. Then the target stores only the
#	difference.
sub _convert ( $source, $target, $backing = undef )
{
	my @cmd = ( 'qemu-img', 'convert', '-O', 'qcow2' );
	push @cmd, '-B', $backing, '-F', 'qcow2' if defined $backing;
	push @cmd, $source, $target;

	my $result = system(@cmd);
	if ( $result != 0 ) {
		warn "qemu-img convert failed for $source\n";
		return 0;
	}

	return 1;
}

# $self->_install_script:
#	Return the installer script whose bytes go into the cache key.
#	The path resolves through App::FuguVM::Console. Thus it is always the
#	same file that run_install would execute.
sub _install_script ($)
{
	return App::FuguVM::Console->script_path(INSTALL_SCRIPT);
}

# $self->_generation_file:
#	Locate share/fuguvm/cache-generation. Its contents rotate the
#	cache key when the install driver changes in ways that the
#	install.exp hash cannot see.
sub _generation_file ($)
{
	return Fugu::File->share_path(
		'share/fuguvm/' . GENERATION_FILE,
		from => __FILE__,
		dist => 'App-FuguVM'
	);
}

sub _sanitize ($value)
{
	$value =~ s/[^\w.]/_/g;
	return $value;
}

1;
