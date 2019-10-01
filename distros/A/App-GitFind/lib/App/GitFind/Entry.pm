# App::GitFind::Entry - Abstract base class representing a file or directory
package App::GitFind::Entry;

use 5.010;
use strict;
use warnings;
use App::GitFind::Base;

our $VERSION = '0.000002';

use parent 'App::GitFind::Class';

# Fields.  Not all have values.  The default stat() returns are provided
# for the convenience of subclasses --- override them in any subclass
# that does not provide _lstat.
use Class::Tiny qw(searchbase);

# Read-only lazy accessors
use Class::Tiny::Immutable {

    # The lstat() results for this entry.  lstat() rather than stat()
    # because searches treat links as individual entries rather than
    # as their referents.  (TODO global option?)
    # This is a lazy initializer so we don't stat() if we don't have to.
    _lstat => sub { ... },
        # Returns an arrayref of lstat() results.  Must be overriden in
        # subclasses unless the below uses of _lstat are overridden.

    dev => sub { $_[0]->_lstat->[0] },      # device number of filesystem
    ino => sub { $_[0]->_lstat->[1] },      # inode number
    mode => sub { $_[0]->_lstat->[2] },     # file mode  (type and permissions)
    nlink => sub { $_[0]->_lstat->[3] },    # number of (hard) links to the file
    uid => sub { $_[0]->_lstat->[4] },      # numeric user ID of file's owner
    gid => sub { $_[0]->_lstat->[5] },      # numeric group ID of file's owner
    rdev => sub { $_[0]->_lstat->[6] },     # the device identifier (special files only)
    size => sub { $_[0]->_lstat->[7] },     # total size of file, in bytes
    atime => sub { $_[0]->_lstat->[8] },    # last access time in seconds since the epoch
    mtime => sub { $_[0]->_lstat->[9] },    # last modify time in seconds since the epoch
    ctime  => sub { $_[0]->_lstat->[10] },  # inode change time in seconds since the epoch (*)
    blksize => sub { $_[0]->_lstat->[11] }, # preferred I/O size in bytes for interacting with the file (may vary from file to file)
    blocks => sub { $_[0]->_lstat->[12] },  # actual number of system-specific blocks allocated
};

# Docs {{{1

=head1 NAME

App::GitFind::Entry - Abstract base class representing a file or directory

=head1 SYNOPSIS

This represents a single file or directory being checked against an expression.
Concrete subclasses implement various types of entries.

=head1 MEMBERS

=head2 searchbase

Required L<Path::Class::Dir>.  Results will be reported relative to this
directory.

=head1 METHODS

=cut

# }}}1

=head2 isdir

Truthy if it's a directory; falsy otherwise.
Must be overriden by subclasses.

=cut

sub isdir { ... }

=head2 name

Basename of this entry.
Must be overriden by subclasses.
TODO May be a string or a Path::Class instance?

=cut

sub name { ... }

=head2 path

Full path of the entry with respect to L</searchbase>.
Must be overriden by subclasses.
May be a string or a Path::Class instance?

=cut

sub path { ... }

=head2 prune

If this entry represents a directory, mark its children as not to be traversed.

If this entry represents a file, no effect.

=cut

sub prune {
    ...
}

=head2 BUILD

Enforce abstractness, and the requirement to provide a C<searchbase>.

=cut

sub BUILD {
    my $self = shift;
    croak "Cannot instantiate abstract base class" if ref $self eq __PACKAGE__;

    croak "Usage: @{[ref $self]}->new(-searchbase=>...)"
        unless $self->searchbase;
    croak "-searchbase must be a App::GitFind::PathClassMicro::Dir"
        unless $self->searchbase->DOES('App::GitFind::PathClassMicro::Dir');
} #BUILD()

1;
