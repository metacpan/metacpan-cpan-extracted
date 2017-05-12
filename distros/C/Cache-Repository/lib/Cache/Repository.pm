package Cache::Repository;

our $VERSION = '0.07';

use strict;
use warnings;
use IO::File;
use Carp;

=head1 NAME

Cache::Repository - Generic repository of files

=head1 SYNOPSIS

  my $rep = Cache::Repository->new(
      style => 'Filesys',
      # options for the F::R driver
    );
  $rep->add_files(tag => 'groupname',
                  files => \@filenames,
                  basedir => '/tmp',
                  move => 1,
                 );
  $rep->add_filehandle(tag => 'anothergroup',
                       filename => 'blah',
                       filehandle => $fh,
                       mode => 0755);
  $rep->set_meta(tag => 'groupname',
                 meta => {
                     title => 'blah',
                     author => 'foo',
                 });

  $rep->retrieve(tag => 'groupname', dest => '/newdir');
  my $data = $rep->get_meta(tag => 'groupname');

=head1 DESCRIPTION

This module is intended to serve as a repository for files, whether those
files are local or remote.  Different drivers can work independantly to
provide differing backing stores.  For example, one driver can use a
locally-mounted filesystem (even if that is a network filesystem), another
could use FTP or HTTP, another could use gmail, and another could use a
relational database such as MySQL or DB2.

Drivers may choose to compress the repository, unless explicitly told
otherwise.

Keeping this in mind, the API presented here cannot expose things that are
not generic to other possible implementations.  That said, some possible
implementations may not allow adding ("sending" to a web server) - it is
expected that they will either throw an exception, or take extra params for
FTP'ing to the server.

=head1 FUNCTIONS

=over 4

=item new

Cache::Repository constructor.  The constructor will load the driver and
return an object of the driver package.  All other parameters will be passed
to the driver for initialisation.

    my $r = Cache::Repository->new(
                                  style => 'Filesys',
                                  # ...
                                 );

It is up to the underlying driver to determine if the repository created
by this is persistant for other processes (e.g., meta-data or even data stored
in RAM wouldn't be persistant), or to handle locking issues should multiple
processes be accessing the repository simultaneously.

Parameters:

=over 4

=item style

This is the name of the driver.  The driver is expected to be
Cache::Compress::I<style>, e.g., Cache::Compress::Filesys

=item (others)

As required by the underlying driver.

=back

Suggested parameters for drivers:

=over 4

=item clear

If true, clear the repository (if it exists) to start anew.  Existing files
and meta information will all be removed.

=item compress

If true, the driver should compress the files and/or meta information if it is
able to, and if it is capable of doing so (drivers do not need to implement
this.)  True values may include:

=over 4

=item C<Z> or C<compress>

Compress with the standard compress format.

=item C<gz> or C<gzip>

Compress with gzip-compatable format.

=item C<zip>

Compress with InfoZip-compatable format.

=item C<bz> or C<bzip2>

Compress with bzip2-compatable format.

=item any other truth value

Compress with any format the driver wishes.

=back

If the chosen compression format cannot be acheived, the driver may choose
another format, or choose to not compress.

If false, the driver should not compress the files, even if it can.

If unset, the driver may compress or not, as the driver desires.  Usually
this is the best option for the user since usually whether the repository
is compressed or not should not be important.  Also, the format of the
compression is unimportant.

=back

Returns: The Cache::Repository-derived object, or undef if the driver failed
to initialise.

Alternately, you can instantiate the driver directly, e.g.,

    my $r = Cache::Repository::Filesys->new(%options);

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class || croak "No class given";
    my %opts = @_;

    if ($class eq __PACKAGE__)
    {
        my $style = delete $opts{style};
        $class .= '::' . $style;
        (my $pm = $class) =~ s[::][/]g;
        $pm .= '.pm';
        require $pm;
    }

    $class->new(%opts);
}

=item clear_tag

Clears a tag completely from the repository.  This includes files and meta
information.

Parameters:

=over 4

=item tag

The tag to be cleared.

=back

=cut

sub clear_tag
{
    my $self = shift;
    my %opts = @_;

    die "Driver must override clear_tag";
}

=item add_symlink

Adds a symlink to the repository.  Note that on systems that do not understand
symlinks, this may not actually work.  Even if the storage allows it,
retrieving a symlink may not do what is expected.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.  If the tag already exists,
any files will be added to the tag by default.

=item filename

Filename that is the symlink

=item target

The target that the symlink points at.  The target need not actually exist -
dangling symlinks should work fine.

=back

=cut

sub add_symlink
{
    my $self = shift;
    my %opts = @_;

    die "Driver must provide add_symlink";
}

=item add_files

Adds files to the repository.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.  If the tag already exists,
any files will be added to the tag by default.

=item files

This can be either a single filename, or an array ref of filenames to add.
The filenames may include paths, but may not include the equivalent of
C<File::Spec-E<gt>updir> in any file.  This is largely to keep files
from going out of the "current" directory and into parent or sibling
directories.

=item basedir

Where to look for files listed in the C<files> parameter.  Default is the
current working directory.

=item filename_conversion

This is a multi-pronged tool which is intended to allow the user to rename
files on the way in to the repository.  The default is to leave the filenames
unchanged.

This option may be:

=over 4

=item a single CODE ref

In this case, the code ref should modify $_ to become the new
file name.  Usually this will be something like:

    filename_conversion => sub { s!(path)/([^/.]*)!$2/$1! }

=item a single or array ref of filenames

This works just like the files option.  If the list of files passed in
to this parameter is not of the same length as the list of files, then an
exception is thrown.  If a given filename is undef, the filename is left
unchanged.  For example:

    files => qw(blah foo bar/baz),
    filename_conversion => (undef, qw(floo/foo bar/blah))

This will read from a file named C<blah>, and put it into the repository
without modifying the name.  It will read C<foo> from the current directory
(or the C<basedir> if specified) and put it into the repository in the
C<floo> directory.  And it will read C<bar/baz> and put it in the repository
as C<bar/blah>.

=back

=item move

If set to true, will remove the file after placing it in the repository.
Can also be used for optimisation for a filesystem repository on the same
partition.

=back

Returns: true if all files were added succesfully, false otherwise.

=cut

# Default behaviour - convert into add_filehandle calls.
# Many drivers may find it more efficient to override this directly.
sub add_files
{
    my $self = shift;
    my %opts = @_;

    # We may have a single filename, or an array ref of filenames.
    my @files =
        ref $opts{files} ? @{$opts{files}} : $opts{files};

    my @renames;
    my $rename_sub;
    if (exists $opts{filename_conversion})
    {
        if (ref $opts{filename_conversion} and
            ref $opts{filename_conversion} eq 'CODE')
        {
            $rename_sub = $opts{filename_conversion};
        }
        else
        {
            @renames =
                ref $opts{filename_conversion} ? @{$opts{filename_conversion}} : $opts{filename_conversion};
            die "filename_conversion is not as long as files"
                unless scalar @files == scalar @renames;
        }
    }

    require File::stat;
    foreach my $f (@files)
    {
        my $fullname = $f;
        if ($opts{basedir})
        {
            $fullname = File::Spec->catfile($opts{basedir}, $fullname);
        }
        my $repositoryname = $f;
        if (@renames)
        {
            $repositoryname = shift @renames;
        }
        elsif ($rename_sub)
        {
            local $_ = $repositoryname;
            $rename_sub->();
            $repositoryname = $_;
        }

        if (-l $fullname)
        {
            $self->add_symlink(
                               tag => $opts{tag},
                               filename => $repositoryname,
                               target => readlink($fullname),
                              ) or return 0;
        }
        else
        {
            my $s = File::stat::stat($fullname);
            my $fh = IO::File->new($fullname, 'r') or do {
                warn "Can't open $fullname: $!";
                return 0;
            };
            binmode $fh;
            my %file_opts = (
                             filename => $repositoryname,
                             filehandle => $fh,
                             mode => $s->mode(),
                             owner => $s->uid(),
                             group => $s->gid(),
                            );
            $self->add_filehandle(tag => $opts{tag}, %file_opts) or return 0;
        }
        unlink($f) if $opts{move};
    }
    1;
}

=item add_filehandle

Adds a file to the repository.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.  If the tag already exists,
any files will be added to the tag by default.

=item filehandle

You can pipe your data directly into
the repository.  This filehandle can be any perl-ish filehandle object:
a GLOB, an IO::Handle (including an IO::String), or anything else that works
like a file handle to be read from.  Note that perl can open from a string
reference in v5.8, so that is viable as well.

The filehandle will be read from, and the data written directly to the
repository, and should be done in a loop such that the entire file need
not be brought into memory.  For example, during an FTP transfer, the
filehandle will be read so that it can be put directly to the server.

The filename that is used is the C<filename> parameter.

Note that only one filehandle can be added at a time.

=item filename

The filename for the filehandle.  Again, this filename may include
subdirectories, but cannot be an absolute path nor include the updir
string.

=item mode

Attributes for the file.  Normally these would be read directly from the input
file, but cannot be read from a filehandle, so this will need to be provided.

=item owner

The UID for the owner of the file.  Note that without root authority,
this may fail.  Default is the file's owner, or the current user if the source
is a filehandle.

=item group

The GID for the owner of the file.  Note that without root authority,
this may fail.  Default is the file's owner, or the current group if the source
is a filehandle.

=back

Returns: true if the repository was successfully added.

=cut

sub add_filehandle
{
    die __PACKAGE__ . " driver must implement add_filehandle."
}

=item retrieve

Retrieves all the files associated with the given tag to the location
specified.

Parameters:

=over 4

=item tag

Required.  The tag to retrieve.

=item basedir

The location to place the file(s).  Note that any files that were placed
into the repository with subdirectories will be placed in a subdirectory
relative to this basedir.

=item files

The list of files to be retrieved.  Defaults to all files.  This parameter
may be a simple scalar, or an array ref, e.g.,

    files => 'foo.txt'

or

    files => [ 'foo.txt' ]

are both the same.

=back

Returns undef if the tag doesn't exist, or 0 for any other retrieval error.

=cut

sub retrieve
{
    my $self = shift;
    my %opts = @_;

    my $rc = 1;
    my $fh = undef;
    my $filename;

    my $callback = sub {
        my %cb_opts = @_;
        # filename, data, start, end, error

        if ($cb_opts{error})
        {
            $rc = 0;
            warn $cb_opts{error};
            return 0;
        }

        if ($cb_opts{target})
        {
            $filename = File::Spec->catfile($opts{basedir},$cb_opts{filename});
            symlink($cb_opts{target}, $filename);
            return 1;
        }

        if ($cb_opts{start})
        {
            require File::Path;
            require File::Basename;

            $filename = File::Spec->catfile($opts{basedir},$cb_opts{filename});
            File::Path::mkpath(File::Basename::dirname($filename));

            $fh = IO::File->new($filename, "w") or do {
                warn "Can't write to $filename: $!";
                $rc = 0;
                return 0;
            };
            binmode $fh;
        }

        $fh->print($cb_opts{data}) if defined $cb_opts{data};

        if ($cb_opts{end})
        {
            $fh->close();
            $fh = undef;

            chmod $cb_opts{mode}, $filename;
            chown $cb_opts{owner}, $cb_opts{group}, $filename;
        }
        1;
    };

    return undef unless $self->retrieve_with_callback(
                                                      %opts,
                                                      callback => $callback,
                                                     );

    $rc;
}

=item retrieve_as_hash

Retrieves all the files associated with the given tag into memory.  The
hash (or hash-ref in scalar context) is returned.  To use a specific hash,
pass in a ref to it.

Keys to the hash are the filenames.  The values are hashes with keys of:
C<content> (the file contents), C<mode> (file mode), C<owner> (UID for the
file), and C<group> (GID for the file) if the filename is a real file, 
and a key of C<target> if the file is a symlink.

Parameters:

=over 4

=item tag

Required.  The tag to retrieve.

=item hash

If this parameter is specified, this hash ref will be used instead of creating
a new hash ref.  For example:

    my %files;
    my $ref = $rep->retrieve(tag => 'groupname', hash => \%files);
    # \%files == $ref

=item files

The list of files to be retrieved.  Defaults to all files.  This parameter
may be a simple scalar, or an array ref, e.g.,

    files => 'foo.txt'

or

    files => [ 'foo.txt' ]

are both the same.

=back

Returns undef if the retrieval failed.

=cut

sub retrieve_as_hash
{
    my $self = shift;
    my %opts = @_;

    my $hash = $opts{hash} || {};

    my $callback = sub {
        my %cb_opts = @_;
        # filename, data, start, end, error

        if ($cb_opts{error})
        {
            $hash = undef;
            warn $cb_opts{error};
            return 0;
        }

        if ($cb_opts{target})
        {
            $hash->{$cb_opts{filename}}{target} = $cb_opts{target};
            return 1;
        }

        if ($cb_opts{start})
        {
            my @keys = qw[mode owner group];
            my %h;
            @h{@keys} = @cb_opts{@keys};
            $hash->{$cb_opts{filename}} = \%h;
        }

        $hash->{$cb_opts{filename}}{data} .= $cb_opts{data} if $cb_opts{data};
        1;
    };

    return undef unless $self->retrieve_with_callback(
                                                      %opts,
                                                      callback => $callback,
                                                     );

    $hash;

}

=item retrieve_with_callback

Retrieves each file associated with the given tag by calling back to the
specified function.

Parameters:

=over 4

=item tag

Required.  The tag to retrieve.

=item callback

This parameter specifies a code ref which will be called for each file.
The code ref will be given the following parameters on each call.  The
code may be called more than once per file if the file is being retrieved
in chunks.

=over 4

=item filename

The name of the current file.

=item data

The contents of the file, or the current chunk of contents of the file.
May be empty if the previous call happened to contain the end of the file.

=item owner

=item group

=item mode

The owner, group, and mode of the file.

=item start

True if this is the first call for this file.

=item end

True if this is the last call for this file.  Note that start and end may
both be set to true if data contains the entire file.  Also note that
data may be empty if the previous chunk turned out to be the end of the
file.

=item target

The symlink target if the current file is a symlink.  Note that if the
storage supports this, but the current filesystem does no, it is up to the
callback routine to figure out what to do.

=item error

If an error happened during retrieval, this will be the driver-defined error
(string or number).

=back

If the callback returns true, processing will continue, false will abort
the rest of the retrieval.

=item files

The list of files to be retrieved.  Defaults to all files.  This parameter
may be a simple scalar, or an array ref, e.g.,

    files => 'foo.txt'

or

    files => [ 'foo.txt' ]

are both the same.

=back

Returns undef if the tag doesn't exist.

=cut

sub retrieve_with_callback
{
    my $self = shift;
    my %opts = @_;
    die "Driver must implement retrieve_with_callback";
}

=item set_meta

Sets some meta-information for the files.  For example, storing sizes,
MD5s, or other information that your application needs about this group,
other than the files themselves.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.

=item meta

A hash ref of meta information.  This information will be I<added to> the
existing meta information.  Key collisions will replace.  This can be
thought of as:

  %meta = (%old_meta, %new_meta);

=item reset

If this flag is true, the given meta information will replace existing meta
information as in:

  %meta = %new_meta;

completely discarding the old meta information.

=back

Returns: true if successful.

Default implementation stores meta information in memory - this is fine for
single-process repositories that don't need to be persistant across
invocations, but a generic persistant implementation cannot be written outside
of the driver.

=cut

sub set_meta
{
    my $self = shift;
    my %opts = @_;

    my $old_meta = $self->get_meta(%opts);
    my $new_meta = $opts{meta};

    @$old_meta{keys %$new_meta} = values %$new_meta;
    $old_meta;
}

=item get_meta

Retrieves the meta information for a tag.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.

=back

Returns: the meta information in hash-ref form.

=cut

sub get_meta
{
    my $self = shift;
    my %opts = @_;

    unless (exists $self->{meta}{$opts{tag}})
    {
        $self->{meta}{$opts{tag}} = {}
    }
    $self->{meta}{$opts{tag}};
}

=item get_size

Returns the total space requirements of the tag.  Each file is rounded up
to the next K before adding together.  If a file list is given, only those
files are counted.

Symlinks are counted as 1K.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.

=item files

Either a single file, or an array ref of files, which is the file or files
that should be considered part of the size total.

=back

=cut

sub get_size
{
    my $self = shift;
    my %opts = @_;

    die "Driver must implement get_size";
}

=item list_files

Returns a list of the files that are currently stored for the given tag.
Note that if compression is on, the filenames must be the uncompressed names.
If compression is using an archive format (such as C<zip>), this may be
a slow operation unless the driver stores the file list externally to the
archive, or each file is archived/compressed to a separate compressed archive.

Parameters:

=over 4

=item tag

Mandatory identifier for the group of files.

=back

Returns: An array in array context, array ref in scalar context.

=cut

sub list_files
{
    my $self = shift;
    my %opts = @_;

    die "Driver must implement list_files";
}

=item list_tags

Returns a list of all in-use tags.  Note that if there is more than one
process running from the same repository that by the time you get to use the
list, it may have changed (tags being added or removed).

Parameters: None.

Returns: An array in array context, array ref in scalar context.  The
order of tags returned is indetertiminate (may be in insert order, may be
alphabetical, may be pseudo-random).  If a sort order is desired, it is up
to the caller to use meta-information on each tag on which to base a sort,
and to call sort itself.

=cut

sub list_tags
{
    my $self = shift;
    my %opts = @_;

    die "Driver must implement list_tags";
}

=item _is_filename_ok

Checks a filename to see if it is "safe".  We are primarily concerned with
filenames that go up the tree to above the current directory, whether that is
absolute path or using the C<File::Spec-E<gt>updir>.

Returns true if the filename is ok.  Primarily used by the drivers.

=cut

sub _is_filename_ok
{
    my $self = shift;
    my $name = shift;

    require File::Spec;

    # first check if the name is absolute.  That is absolutely a no-go.
    # check both for the current system, and unix-style.
    return undef
        if File::Spec->file_name_is_absolute($name) or
            $name =~ m.^/.;

    # check for any updir's.  Again, check unix-style explicitly as well.
    my ($volume, $path, $file) = File::Spec->splitpath($name);
    my @split = File::Spec->splitdir($path);
    my $updir = File::Spec->updir();
    return undef
        if grep { $_ eq $updir or $_ eq '..' } @split;

    1;
}

=back

=head1 AUTHOR

Darin McBride - dmcbride@cpan.org

=head1 COPYRIGHT

Copyright 2006 Darin McBride.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 BUGS

See TODO file.

=head1 SEE ALSO

L<http://www.perlmonks.org/index.pl?node_id=589209>

=cut

1;
