package DataStore::CAS::FS::DirEnt;
use strict;
use warnings;

our $VERSION= '0.011000';

# ABSTRACT: Light-weight Immutable Directory Entry Object


# We expect other subclasses to be based on different native objects, like
#  arrays, so our accessor pulls from the 'as_hash' so that it can safely
#  return undef if the subclass doesn't support it.
BEGIN {
	eval "sub $_ { \$_[0]->as_hash->{$_} }; 1" or die $@
		for qw(
			name
			type
			ref
			size
			create_ts
			modify_ts
			access_ts
			metadata_ts
			unix_uid
			unix_user
			unix_gid
			unix_group
			unix_mode
			unix_dev
			unix_inode
			unix_nlink
			unix_blocksize
			unix_blockcount
		);
	*unix_atime= *access_ts;
	*unix_ctime= *metadata_ts;
	*unix_mtime= *modify_ts;
}


sub new {
	my $class= shift;
	my $hash= (@_ == 1 and CORE::ref $_[0] eq 'HASH')? $_[0] : { @_ };
	bless \$hash, $class;
}


sub clone {
	my $self= shift;
	CORE::ref($self)->new(
		%{$self->as_hash},
		(@_ == 1 and CORE::ref $_[0] eq 'HASH')? @{$_[0]} : @_
	);
}


sub as_hash { ${$_[0]} }

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::DirEnt - Light-weight Immutable Directory Entry Object

=head1 VERSION

version 0.011000

=head1 DESCRIPTION

DataStore::CAS::FS::DirEnt is a super-light-weight class.  More of an
interface, really.  DirEnt objects should be considered immutable constants,
and all attributes are read-only.  It is of course *possible* to modify them,
but this will break caching features of L<DataStore::CAS::FS>, so don't do that.
In particular, DO NOT modify the hashref returned by L</as_hash>

See the L<clone(%params)|/clone> method for a convenient way to create modified
copies of a DirEnt.

=head1 ATTRIBUTES

Each attribute is optional, except 'name' and 'type'.  Accessors for
non-existent attributes will return undef.  To find out which attributes
actually exist, use the C<as_hash> method and inspect the keys.

=head2 name

The name of this entry within its directory.

Will either be a 7-bit ASCII string, a unicode-flagged string, or an instance
of L<DataStore::CAS::FS::InvalidUTF8> (which stringifies to the original octets).

See L<DataStore::CAS::FS/"UNICODE vs. FILENAMES">.

=head2 type

One of "file", "dir", "symlink", "blockdev", "chardev", "pipe", "socket".

Note that 'symlink' refers only to UNIX style symlinks.
As support is added for other systems' symbolic links, new type strings will
be added to this list, and the type will determine how to interpret the
C<ref> value.

C<type> must always be defined when stored, though instances of DirEnt with an
undefined type might exist temporarily while building a new directory.

=head2 ref

For file or dir: the store's checksum of the referenced data.

For symlink: the path as a string of path parts separated by '/'.

For blockdev and chardev: the device node as a string of "$major,$minor".

Ref is allowed to be undefined (regardless of type) if the data is not known.

=head2 size

The size of the referenced file.  In the case of directories, this is the size
of the serialized directory, if one is referenced.  No other types should have
a size.

=head2 create_ts

The timestamp of the creation of the file, expressed in Unix Epoch seconds.

=head2 modify_ts

The timestamp the file was last modified, expressed in Unix Epoch seconds.

=head2 access_ts

The timestamp the file was last acessed, expressed in Unix Epoch seconds.

=head2 metadata_ts

The timestamp the file's metadata (or content) was last modified, expressed in
Unix Epoch seconds.

=head2 unix_uid

The number reported by lstat for uid.

=head2 unix_gid

The number reported by lstat for gid

=head2 unix_user

The user name corresponding to the unix_uid

=head2 unix_group

The group name corresponding to the unix_gid

=head2 unix_mode

The unix permissions for the entry, as reported by lstat.

=head2 unix_atime

The unix atime, as reported by lstat.

=head2 unix_ctime

The unix ctime, as reported by lstat.

=head2 unix_mtime

An alias for modify_ts.

=head2 unix_dev

The device file number, as reported by lstat.

=head2 unix_inode

The inode number, as reported by lstat.

=head2 unix_nlink

The the hardlink count reported by lstat.

=head2 unix_blocksize

The block size reported by lstat.

=head2 unix_blockcount

The block count reported by lstat.

=head1 METHODS

=head2 new

  $dirEnt= DataStore::CAS::FS::DirEnt->new( %fields | \%fields )

The default constructor *uses* the hashref you pass to it. (it does not clone)
This should be ok, because the DirEnt objects should never be modified.
We don't yet enforce that though, so be careful what you pass to it.

=head2 clone

  $dirEnt2= $dirEnt->clone( %overrides )

Create a new directory entry, with some fields overridden.

Most implementations will simply call C<< new( %{$self->as_hash}, %overrides ) >>,
but in some implementations it might not be possible or practical to apply
the requested overrides, so you might get back a different class than the
original.

=head2 as_hash

  $immutable_hash= $dirEnt->as_hash();

Returns the fields of the directory entry as a hashref.  The hashref will
contain only the public fields.  The hashref might be cached, and SHOULD NEVER
BE MODIFIED.
(Future versions might use perl's constants feature to enforce this)

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
