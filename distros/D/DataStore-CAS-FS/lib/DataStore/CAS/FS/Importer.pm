package DataStore::CAS::FS::Importer;
use 5.008;
use Moo;
use Carp;
use Try::Tiny;
use File::Spec::Functions 'catfile', 'catdir', 'splitpath', 'catpath';
use Fcntl;
use DataStore::CAS::FS::InvalidUTF8;
use DataStore::CAS::FS::DirCodec;

our $VERSION= '0.011000';

# ABSTRACT: Copy files from filesystem into DataStore::CAS::FS.


our %_flag_defaults;
BEGIN {
	%_flag_defaults= (
		die_on_dir_error  => 1,
		die_on_file_error => 1,
		die_on_hint_error => 0,
		die_on_metadata_error => 0,
		collect_metadata_ts => 1,
		collect_access_ts => 0,
		collect_unix_perm => 1,
		collect_unix_misc => 0,
		collect_acl       => 0,
		collect_ext_attr  => 0,
		follow_symlink    => 0,
		cross_mountpoints => 0,
		reuse_digests     => 1,
		utf8_filenames    => 1,
	);
	for (keys %_flag_defaults) {
		eval "sub $_ { \$_[0]{flags}{$_}= \$_[1] if \@_ > 1; \$_[0]{flags}{$_} }; 1" or die $@
	}
}
sub _flag_defaults {
	\%_flag_defaults;
}

has dir_format     => ( is => 'rw', default => sub { 'universal' } );
has filter         => ( is => 'rw' );
has flags          => ( is => 'rw', default => sub { { } } );
has unix_uid_cache => ( is => 'rw', default => sub { {} } );
has unix_gid_cache => ( is => 'rw', default => sub { {} } );
has _hint_check_fn => ( is => 'rwp' );

sub _handle_hint_error {
	croak $_[1] if $_[0]->die_on_hint_error;
	warn "$_[1]\n";
}

sub _handle_file_error {
	croak $_[1] if $_[0]->die_on_file_error;
	warn "$_[1]\n";
}

sub _handle_dir_error {
	croak $_[1] if $_[0]->die_on_dir_error;
	warn "$_[1]\n";
}

sub _handle_metadata_error {
	croak $_[1] if $_[0]->die_on_metadata_error;
	warn "$_[1]\n";
}


sub BUILD {
	my ($self, $args)= @_;
	my $flags= $self->flags;
	my $defaults= $self->_flag_defaults;
	for (keys %$defaults) {
		$flags->{$_}= delete $args->{$_}
			if exists $args->{$_};
		$flags->{$_}= $_flag_defaults{$_}
			unless defined $flags->{$_};
	}
	defined $defaults->{$_} || croak "Unknown flag: '$_'"
		for keys %$flags;
	$self->can($_) || croak "Unknown attribute: '$_'"
		for keys %$args;
}

# locally-scoped to the device number which we should stay on
our $_DEVICE_CONSTRAINT;


sub import_tree {
	my ($self, $src, $dest)= @_;
	
	my $stat= $self->_stat($src)
		or croak "Source does not exist";

	local $_DEVICE_CONSTRAINT= $stat->dev
		unless defined $_DEVICE_CONSTRAINT or $self->cross_mountpoints;

	$self->_build__hint_check_fn;

	my $ent_name= $self->_entname_from_path($src);
	my $ent= $self->_import_directory_entry($dest->filesystem->store, $src, $ent_name, $stat, $dest);
	$dest->filesystem->set_path($dest->path_names, $ent);
	1;
}


sub import_directory {
	my ($self, $cas, $path, $hint)= @_;

	my $stat= $self->_stat($path)
		or croak "Source does not exist";

	local $_DEVICE_CONSTRAINT= $stat->dev
		unless defined $_DEVICE_CONSTRAINT or $self->cross_mountpoints;

	$self->_build__hint_check_fn;

	$self->_import_directory($cas, $path, $hint);
}

sub _import_directory {
	my ($self, $cas, $path, $hint)= @_;
	my $names= $self->_readdir($path)
		or return undef;
	my @entries;
	my $filter= $self->filter;
	for my $ent_name (@$names) {
		my $ent_path= catfile($path, $ent_name);
		my $stat= $self->_stat($ent_path);

		if ($self->utf8_filenames) {
			$ent_name= DataStore::CAS::FS::InvalidUTF8->decode_utf8($ent_name);
		} else {
			utf8::upgrade($ent_name);
		}

		my $keep= $filter? $filter->($ent_name, $ent_path, $stat) : 1;
		next unless $keep;

		# Check for crossing mount point.
		if (defined $_DEVICE_CONSTRAINT && $stat->dev ne $_DEVICE_CONSTRAINT) {
			# TODO: log skipped mount points
			# Metadata comes from mounted filesystem, so ignore it
			push @entries, { type => 'dir', name => $ent_name };
		}
		# If keep is < 0, store the metadata but not the file/dir
		elsif ($keep < 0) {
			push @entries, $self->collect_dirent_metadata($ent_path, $ent_name, $stat);
		}
		# Else recursively store the whole thing
		else {
			push @entries, $self->_import_directory_entry($cas, $ent_path, $ent_name, $stat, $hint);
		}
	}
	return DataStore::CAS::FS::DirCodec->put($cas, $self->dir_format, \@entries, {} );
}


sub import_directory_entry {
	my ($self, $cas, $path, $ent_name, $stat, $hint)= @_;

	$stat||= $self->_stat($path)
		or croak "Source does not exist";

	$self->_build__hint_check_fn;

	local $_DEVICE_CONSTRAINT= $stat->dev
		unless defined $_DEVICE_CONSTRAINT or $self->cross_mountpoints;

	$ent_name= $self->_entname_from_path($path)
		unless defined $ent_name;
	return DataStore::CAS::FS::DirEnt->new(
		$self->_import_directory_entry($cas, $path, $ent_name, $stat, $hint)
	);
}

sub _import_directory_entry {
	my ($self, $cas, $ent_path, $ent_name, $stat, $hint)= @_;
	my $attrs= $self->collect_dirent_metadata($ent_path, $ent_name, $stat)
		or croak "Path does not exist: '$ent_path'";
	if ($attrs->{type} eq 'file') {
		if ($hint && $self->_can_reuse_hash($attrs, $hint)) {
			$attrs->{ref}= $hint->ref;
		} else {
			my $err;
			$attrs->{ref}= try { $cas->put_file($ent_path); } catch { $err= $_; undef; };
			$self->_handle_file_error("Error while importing file '$ent_path': $err")
				if defined $err;
		}
	}
	elsif ($attrs->{type} eq 'dir') {
		if (defined $_DEVICE_CONSTRAINT && $stat->dev ne $_DEVICE_CONSTRAINT) {
			# TODO: log skipped mount points
		} else {
			local $_DEVICE_CONSTRAINT= $stat->dev
				unless defined $_DEVICE_CONSTRAINT || $self->cross_mountpoints;

			my $subdir_hint;
			if (defined $hint) {
				my $err;
				try {
					$subdir_hint= $hint->path_if_exists($attrs->{name});
					$subdir_hint->resolve
						if $subdir_hint;
				} catch {
					$err= $_;
				};
				$self->_handle_hint_error("Error while loading virtual path '".$hint->resolved_canonical_path.'/'.$attrs->{name}."': $err")
					if defined $err;
			}
			$attrs->{ref}= $self->_import_directory($cas, $ent_path, $subdir_hint);
		}
	}
	return $attrs;
}


our %_ModeToType;
# Making this a function allows other code to call it in a BEGIN block if needed
sub _build_ModeToType {
	local $@;
	eval { $_ModeToType{Fcntl::S_IFREG()}= 'file'     };
	eval { $_ModeToType{Fcntl::S_IFDIR()}= 'dir'      };
	eval { $_ModeToType{Fcntl::S_IFLNK()}= 'symlink'  };
	eval { $_ModeToType{Fcntl::S_IFBLK()}= 'blockdev' };
	eval { $_ModeToType{Fcntl::S_IFCHR()}= 'chardev'  };
	eval { $_ModeToType{Fcntl::S_IFIFO()}= 'pipe'     };
	eval { $_ModeToType{Fcntl::S_IFWHT()}= 'whiteout' };
	eval { $_ModeToType{Fcntl::S_IFSOCK()}= 'socket'  };
}

_build_ModeToType();

sub collect_dirent_metadata {
	my ($self, $path, $ent_name, $stat)= @_;
	
	$stat ||= $self->_stat($path)
		or return undef;

	$ent_name= $self->_entname_from_path($path)
		unless defined $ent_name;
	
	my %attrs= (
		type => ($_ModeToType{$stat->[2] & Fcntl::S_IFMT()}),
		name => $ent_name,
		size => $stat->[7],
		modify_ts => $stat->[9],
	);
	if (!defined $attrs{type}) {
		$self->_handle_dir_error("Type of dirent is unknown: ".($stat->[2] & Fcntl::S_IFMT()));
		$attrs{type}= 'file';
	}
	if ($self->{flags}{collect_unix_perm}) {
		$attrs{unix_mode}= ($stat->[2] & ~Fcntl::S_IFMT());
		my $uid= $attrs{unix_uid}= $stat->[4];
		if (my $cache= $self->unix_uid_cache) {
			if (!exists $cache->{$uid}) {
				my $name= getpwuid($uid);
				if (!defined $name) {
					$self->_handle_metadata_error("No username for UID $uid");
				} elsif ($self->utf8_filenames) {
					$name= DataStore::CAS::FS::InvalidUTF8->decode_utf8($name);
				} else {
					utf8::upgrade($name);
				}
				$cache->{$uid}= $name;
			}
			$attrs{unix_user}= $cache->{$uid}
				if defined $cache->{$uid};
		}
		my $gid= $attrs{unix_gid}= $stat->[5];
		if (my $cache= $self->unix_gid_cache) {
			if (!exists $cache->{$gid}) {
				my $name= getgrgid($gid);
				if (!defined $name) {
					$self->_handle_metadata_error("No groupname for GID $gid");
				} elsif ($self->utf8_filenames) {
					$name= DataStore::CAS::FS::InvalidUTF8->decode_utf8($name);
				} else {
					utf8::upgrade($name);
				}
				$cache->{$gid}= $name;
			}
			$attrs{unix_group}= $cache->{$gid}
				if defined $cache->{$gid};
		}
	}
	if ($self->{flags}{collect_metadata_ts}) {
		$attrs{metadata_ts}= $stat->[10];
	}
	if ($self->{flags}{collect_access_ts}) {
		$attrs{access_ts}= $stat->[8];
	}
	if ($self->{flags}{collect_unix_misc}) {
		$attrs{unix_dev}= $stat->[0];
		$attrs{unix_inode}= $stat->[1];
		$attrs{unix_nlink}= $stat->[3];
		$attrs{unix_blocksize}= $stat->[11];
		$attrs{unix_blockcount}= $stat->[12];
	}
	if ($self->{flags}{collect_acl}) {
		# TODO
	}
	if ($self->{flags}{collect_ext_attr}) {
		# TODO
	}
	if ($attrs{type} eq 'dir') {
		delete $attrs{size};
	}
	elsif ($attrs{type} eq 'symlink') {
		$attrs{ref}= readlink $path;
	}
	elsif ($attrs{type} eq 'blockdev' or $attrs{type} eq 'chardev') {
		$attrs{ref}= $self->_split_dev_node($stat->[6]);
	}
	\%attrs;
}

sub _build__hint_check_fn {
	my $self= shift;
	my $reuse= $self->reuse_digests;
	return $self->{_hint_check_fn}= $reuse > 1?
		($reuse > 2? \&_hint_check_ctime : \&_hint_check_mtime)
		: ($reuse > 0? \&_hint_check_size : \&_hint_check_none);
}

sub _hint_check_none {
	return undef;
}
sub _hint_check_size {
	my ($self, $attrs, $hint)= @_;
	return undef unless defined $hint && defined $hint->ref;
	my ($size, $h_size)= ($attrs->{size}, $hint->size);
	return defined $size && defined $h_size && $size eq $h_size;
}
sub _hint_check_mtime {
	my ($self, $attrs, $hint)= @_;
	return undef unless defined $hint && defined $hint->ref;
	my ($size, $h_size)= ($attrs->{size}, $hint->size);
	return undef unless defined $size && defined $h_size && $size eq $h_size;
	my ($modify_ts, $h_modify_ts)= ($attrs->{modify_ts}, $hint->modify_ts);
	return defined $modify_ts && defined $h_modify_ts && $modify_ts eq $h_modify_ts;
}
sub _hint_check_ctime {
	my ($self, $attrs, $hint)= @_;
	return undef unless defined $hint && defined $hint->ref;
	my ($size, $h_size)= ($attrs->{size}, $hint->size);
	return undef unless defined $size && defined $h_size && $size eq $h_size;
	my ($modify_ts, $h_modify_ts)= ($attrs->{metadata_ts}, $hint->metadata_ts);
	return defined $modify_ts && defined $h_modify_ts && $modify_ts eq $h_modify_ts;
}

sub _entname_from_path {
	my ($self, $path)= @_;
	my (undef, undef, $ent_name)= splitpath($path);
	if ($self->utf8_filenames) {
		$ent_name= DataStore::CAS::FS::InvalidUTF8->decode_utf8($ent_name);
	} else {
		utf8::upgrade($ent_name);
	}
	$ent_name;
}

sub _split_dev_node {
	($_[1] >> 8).','.($_[1] & 0xFF);
}

sub _stat {
	my $fn= \&_stat_unix;
	no warnings 'redefine';
	*_stat= $fn;
	goto $fn;
}

sub _stat_unix {
	my ($self, $path)= @_;
	my @stat= $self->follow_symlink? stat($path) : lstat($path);
	unless (@stat) {
		$self->_handle_dir_error("Can't stat '$path': $!");
		return undef;
	}
	bless \@stat, 'DataStore::CAS::FS::Importer::FastStat';
}

sub _readdir {
	my $fn= \&_readdir_unix;
	no warnings 'redefine';
	*_readdir= $fn;
	goto $fn;
}

sub _readdir_unix {
	my ($self, $path)= @_;
	my $dh;
	if (!opendir($dh, $path)) {
		$self->_handle_dir_error("opendir($path): $!");
		return undef;
	}

	my @names= grep { $_ ne '.' && $_ ne '..' } readdir($dh);

	if (!closedir $dh) {
		$self->_handle_dir_error("closedir($path): $!");
		return undef;
	}

	\@names;
}

package DataStore::CAS::FS::Importer::FastStat;
use strict;
use warnings;


sub dev     { $_[0][0] }
sub ino     { $_[0][1] }
sub mode    { $_[0][2] }
sub nlink   { $_[0][3] }
sub uid     { $_[0][4] }
sub gid     { $_[0][5] }
sub rdev    { $_[0][6] }
sub size    { $_[0][7] }
sub atime   { $_[0][8] }
sub mtime   { $_[0][9] }
sub ctime   { $_[0][10] }
sub blksize { $_[0][11] }
sub blocks  { $_[0][12] }

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::Importer - Copy files from filesystem into DataStore::CAS::FS.

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  my $cas_fs= DataStore::CAS::FS->new( ... );
  
  # Defaults are reasonable
  my $importer= DataStore::CAS::FS::Importer->new();
  $importer->import_tree( "/home/user", $cas_fs->path('/') );
  $cas_fs->commit();
  
  # Lots of customizability...
  $importer= DataStore::CAS::FS::Importer->new(
    dir_format => 'unix',   # optimized for storing unix-attrs
    filter => sub { return ($_[0] =~ /^\./)? 0 : 1 }, # exclude hidden files
    die_on_file_error => 0, # store placeholder for files that can't be read
  );

=head1 DESCRIPTION

The Importer is a utility class which performs the work of scanning directory
entries of the real filesystem, storing new files in the CAS, and encoding
new directories and storing those in the CAS as well.  It has conditional
support for the various Perl modules you need to collect all the metadata you
care about, and can be subclassed if you need to collect additional metadata.

=head1 ATTRIBUTES

=head2 dir_format

  $class->new( dir_format => 'universal' );
  $importer->dir_format( 'unix' );

Read/write.  Directory format to use when encoding directories.  Defaults to
C<'universal'>.

Directories can be recorded with varying levels of metadata and encoded in a
variety of formats which are optimized for various uses.  Set this to the
format string of your preferred encoder.

The format strings are registered by L<DirCodec|DataStore::CAS::FS::DirCodec>
classes when loaded.  Built-in formats are 'universal', 'minimal', or 'unix'.
(more are planned)

Calls to L</import_tree> will encode directories in this format.  If you wish
to re-use the previously encoded directories during an incremental backup, you
must use the same C<dir_format> as before.  This is because all directories
get re-encoded every time, and the ones containing the same metadata will end
up with the same digest-hash, and be re-used.

=head2 filter

Read/write.  This optional coderef (which may be an object with overloaded
function operator) filters out files that you wish to ignore when walking
the physical filesystem.

It is passed 3 arguments: The name, the full path, and the results of 'stat'
as a blessed arrayref.  You are also guaranteed that stat was called
on this file immediately preceeding, so you may also use code like "-d _".

Return 0 to exclude the file.  Return 1 to store it.  Return -1 to record its
metadata (directory entry) but not its content.

  $importer->filter( sub {
    my ($name, $path, $stat)= @_;
    return 1 if -d _;                     # recurse into all directories
    return -1 if $stat->size > 1024*1024; # don't store large files
    return 0 if substr($name,0,1) eq '.'; # exclude hidden files
    return 1;
  });

=head2 flags

Read/write.  This is a hashref of parameters and options for how directories
should be scanned and which information is collected.  Each member of 'flags'
has its own accessor method, but they may be accessed here for easy swapping
of entire parameter sets.  All flags are read/write, and most are simple
booleans.

=over

=item C<die_on_dir_error>

true: Die if there is any problem reading the contents of a directory.
false: Warn, and encode as a content-less directory.

Default: true

=item C<die_on_file_error>

true: Die if there is any problem reading the contents of a file.
false: Warn, and encode as a content-less file.

Default: true

=item C<die_on_hint_error>

true: Die if there is an error looking up the "hint" for an incremental backup.
false: Warn that the hint is unavailable, and just encode the file/directory as
if no hint were being used.

Default: false

=item collect_metadata_ts

Default: true, if available and distinct from mtime.

If true, collect C<metadata_ts>, which is the timestamp of the last change to
the file's metadata. (ctime, on UNIX)

=item collect_access_ts

Default: false

If true, collects attribute
L<unix_atime|DataStore::CAS::FS::DirEnt/access_ts>

This value is not collected by default because it changes frequently, many
people don't use it anyway, and the Importer itself is likely to modify them.

=item collect_unix_perm

Default: true on unix

If true, collects attributes
L<mode|DataStore::CAS::FS::DirEnt/mode>,
L<unix_uid|DataStore::CAS::FS::DirEnt/unix_uid>,
L<unix_gid|DataStore::CAS::FS::DirEnt/unix_gid>,
L<unix_user|DataStore::CAS::FS::DirEnt/unix_user>, and
L<unix_group|DataStore::CAS::FS::DirEnt/unix_group>.

=item collect_unix_misc

Default: false

If true, collects attributes
L<unix_dev|DataStore::CAS::FS::DirEnt/unix_dev>,
L<unix_inode|DataStore::CAS::FS::DirEnt/unix_inode>,
L<unix_nlink|DataStore::CAS::FS::DirEnt/unix_nlink>,
L<unix_blocksize|DataStore::CAS::FS::DirEnt/unix_blocksize>, and
L<unix_blockcount|DataStore::CAS::FS::DirEnt/unix_blockcount>.

=item collect_acl

Default: false

If true, would collect attribute C<unix_acl> or C<windows_acl>
(neither of which are currently unimplemented, or have even been spec'd out)

=item collect_ext_attr

Default: false

If true, collects any "extended metadata" available for the file.
This is unimplemented and attributes have not been spec'd out yet.

=item follow_symlink

Default: false.

Use lstat instead of stat.  Use this flag at your own risk.  It might
introduce recursion, and no code has been written yet to detect and prevent
this.  No symlinks will be recorded as symlinks if this is set.

The interaction of this flag with an incremental backup that contains symlinks
(i.e. whether to follow symlinks within the "hint" directory) is unspecified.  
(I need to spend some time thinking about it before I can decide which makes
the most sense)

=item cross_mountpoints

Default: false

Cross mount points.  Leaving this as false will record mount points as a
content-less directory.  Mount points are detected by the device number
changing in a call to stat.  This is not robust protection against bind-mounts,
however.  Support for detecting bind-mounts might be added in the future.

=item reuse_digests

Default: 2

Options: false (off), 1 (size), 2 (size+mtime), 3 (size+ctime)

Many of the import methods accept a C<$hint> parameter.  Using digest hints
greatly speeds up import operations, at the cost of the certainty of getting
an exact copy.

The hint is a past result of importing a tree from the filesystem.
(a L<path object|DataStore::CAS::FS/"PATH OBJECTS"> from DataStore::CAS::FS).
If the size (and optionally metadata_ts / modify_ts) of the file have not
changed, the digest_hash from the hint will be used instead of re-calculating
it.

Make sure you are collecting and storing your criteria in the directories,
or none of the hashes can be re-used.  Specifically, you need
C<collect_metadata_ts =E<gt> 1> and C<dir_format =E<gt> 'unix'> or
C<dir_format =E<gt> 'universal'> to make use of C<reuse_digests =E<gt> 3>.

=item utf8_filenames

=back

=head1 METHODS

=head2 new

  my $importer= $class->new( %attributes_and_flags )

The constructor accepts values for any of the official attributes.  It also
accepts all of the L<flag names|/flags>, and will move them into the C<flags>
attribute for you.

No arguments are required, and the defaults should work for most people.

=for Pod::Coverage BUILD

=head2 import_tree

  $self->import_tree( $path, $FS_Path_object )
  # returns true, or throws an exception

Recursively collect directory entries from the real filesystem at C<$path>
and store them at L<$FS_Path_object|DataStore::CAS::FS/"PATH OBJECTS">
(which references an instance of L<FS|DataStore::CAS::FS>, which references
an instance of L<CAS|DataStore::CAS>)

This will use the destination path for incremental-bakup hints, if that
feature is enabled on this Importer.  If you want to make a clean import,
you should first unlink the destination path, or turn off the
L</reuse_digests> flag.

=head2 import_directory

  $digest_hash= $importer->import_directory( $cas, $path, $hint );

Imports a directory from the real filesystem C<$path> into the
L<$cas|DataStore::CAS>, optionally using the virtual filesystem path
L<$hint|DataStore::CAS::FS/"PATH OBJECTS"> as a cache of previously-calculated
digest hashes for files whose metadata matches.

=head2 import_directory_entry

  $dirEnt= $importer->import_directory_entry($cas, $path);
  # Or a little more optimized...
  $dirEnt= $importer->import_directory_entry($cas, $path, $ent_name, $stat, $hint);

This method scans a path on the real filesystem, and returns a *complete*
L<DirEnt object|DataStore::CAS::FS::DirEnt>, importing file contents and
recursing and encoding subdirectories as necessary.

=head2 collect_dirent_metadata

  $attrHash= $importer->collect_dirent_metadata( $path );
  # -or-
  $attrHash= $importer->collect_dirent_metadata( $path, $hint, $name, $stat );

This method returns a hashref of attributes about the named file.  The only
required parameter is C<$path>, however the others can be given to speed up
execution.  C<$path> should be in platform-native form.  C<$name> will be
calculated with File::Spec->splitpath if not provided.  C<$stat> should be an
arrayref from stat() or lstat(), optionally blessed.

If C<$hint> (a L<DirEnt|DataStore::CAS::FS::DirEnt>) is given, and C<$path>
refers to a file with the same metadata (size, mtime) of the C<$hint>, then
C<$hint->ref> will be used instead of re-calculating the digest of the file.

=head1 STAT OBJECTS

The stat arrayrefs that Importer passes to the filter are blessed to give you
access to methods like '->mode' and '->mtime', but I'm not using File::stat.
"Why??" you ask? because blessing an arrayref from the regular stat is 3 times
as fast and my accessors are twice as fast, and it requires a miniscule amount
of code.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
