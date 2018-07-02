# NAME

Archive::Tar::Wrapper - API wrapper around the 'tar' utility

# SYNOPSIS

    use Archive::Tar::Wrapper;

    my $arch = Archive::Tar::Wrapper->new();

        # Open a tarball, expand it into a temporary directory
    $arch->read("archive.tgz");

        # Iterate over all entries in the archive
    $arch->list_reset(); # Reset Iterator
                         # Iterate through archive
    while(my $entry = $arch->list_next()) {
        my($tar_path, $phys_path) = @$entry;
        print "$tar_path\n";
    }

        # Get a huge list with all entries
    for my $entry (@{$arch->list_all()}) {
        my($tar_path, $real_path) = @$entry;
        print "Tarpath: $tar_path Tempfile: $real_path\n";
    }

        # Add a new entry
    $arch->add($logic_path, $file_or_stringref);

        # Remove an entry
    $arch->remove($logic_path);

        # Find the physical location of a temporary file
    my($tmp_path) = $arch->locate($tar_path);

        # Create a tarball
    $arch->write($tarfile, $compress);

# DESCRIPTION

Archive::Tar::Wrapper is an API wrapper around the 'tar' command line
utility. It never stores anything in memory, but works on temporary
directory structures on disk instead. It provides a mapping between
the logical paths in the tarball and the 'real' files in the temporary
directory on disk.

It differs from Archive::Tar in two ways:

- Archive::Tar::Wrapper doesn't hold anything in memory. Everything is
stored on disk.
- Archive::Tar::Wrapper is 100% compliant with the platform's `tar`
utility, because it uses it internally.

# METHODS

- **my $arch = Archive::Tar::Wrapper->new()**

    Constructor for the tar wrapper class. Finds the `tar` executable
    by searching `PATH` and returning the first hit. In case you want
    to use a different tar executable, you can specify it as a parameter:

        my $arch = Archive::Tar::Wrapper->new(tar => '/path/to/tar');

    Since `Archive::Tar::Wrapper` creates temporary directories to store
    tar data, the location of the temporary directory can be specified:

        my $arch = Archive::Tar::Wrapper->new(tmpdir => '/path/to/tmpdir');

    Tremendous performance increases can be achieved if the temporary
    directory is located on a ram disk. Check the "Using RAM Disks"
    section below for details.

    Additional options can be passed to the `tar` command by using the
    `tar_read_options` and `tar_write_options` parameters. Example:

         my $arch = Archive::Tar::Wrapper->new(
                       tar_read_options => "p"
                    );

    will use `tar xfp archive.tgz` to extract the tarball instead of just
    `tar xf archive.tgz`. Gnu tar supports even more options, these can
    be passed in via

         my $arch = Archive::Tar::Wrapper->new(
                        tar_gnu_read_options => ["--numeric-owner"],
                    );

    Similarily, `tar_gnu_write_options` can be used to provide additional
    options for Gnu tar implementations. For example, the tar object

        my $tar = Archive::Tar::Wrapper->new(
                      tar_gnu_write_options => ["--exclude=foo"],
                  );

    will call the `tar` utility internally like

        tar cf tarfile --exclude=foo ...

    when the `write` method gets called.

    By default, the `list_*()` functions will return only file entries.
    Directories will be suppressed. To have `list_*()`
    return directories as well, use

         my $arch = Archive::Tar::Wrapper->new(
                       dirs  => 1
                    );

    If more files are added to a tarball than the command line can handle,
    `Archive::Tar::Wrapper` will switch from using the command

        tar cfv tarfile file1 file2 file3 ...

    to

        tar cfv tarfile -T filelist

    where `filelist` is a file containing all file to be added. The default
    for this switch is 512, but it can be changed by setting the parameter
    `max_cmd_line_args`:

         my $arch = Archive::Tar::Wrapper->new(
             max_cmd_line_args  => 1024
         );

- **$arch->read("archive.tgz")**

    `read()` opens the given tarball, expands it into a temporary directory
    and returns 1 on success or `undef` on failure.
    The temporary directory holding the tar data gets cleaned up when `$arch`
    goes out of scope.

    `read` handles both compressed and uncompressed files. To find out if
    a file is compressed or uncompressed, it tries to guess by extension,
    then by checking the first couple of bytes in the tarfile.

    If only a limited number of files is needed from a tarball, they
    can be specified after the tarball name:

        $arch->read("archive.tgz", "path/file.dat", "path/sub/another.txt");

    The file names are passed unmodified to the `tar` command, make sure
    that the file paths match exactly what's in the tarball, otherwise
    `read()` will fail.

- **$arch->list\_reset()**

    Resets the list iterator. To be used before the first call to
    **$arch-**list\_next()>.

- **my($tar\_path, $phys\_path, $type) = $arch->list\_next()**

    Returns the next item in the tarfile. It returns a list of three scalars:
    the relative path of the item in the tarfile, the physical path
    to the unpacked file or directory on disk, and the type of the entry
    (f=file, d=directory, l=symlink). Note that by default,
    Archive::Tar::Wrapper won't display directories, unless the `dirs`
    parameter is set when running the constructor.

- **my $items = $arch->list\_all()**

    Returns a reference to a (possibly huge) array of items in the
    tarfile. Each item is a reference to an array, containing two
    elements: the relative path of the item in the tarfile and the
    physical path to the unpacked file or directory on disk.

    To iterate over the list, the following construct can be used:

        # Get a huge list with all entries
        for my $entry (@{$arch->list_all()}) {
            my($tar_path, $real_path) = @$entry;
            print "Tarpath: $tar_path Tempfile: $real_path\n";
        }

    If the list of items in the tarfile is big, use `list_reset()` and
    `list_next()` instead of `list_all`.

- **$arch->add($logic\_path, $file\_or\_stringref, \[$options\])**

    Add a new file to the tarball. `$logic_path` is the virtual path
    of the file within the tarball. `$file_or_stringref` is either
    a scalar, in which case it holds the physical path of a file
    on disk to be transferred (i.e. copied) to the tarball, or it is
    a reference to a scalar, in which case its content is interpreted
    to be the data of the file.

    If no additional parameters are given, permissions and user/group
    id settings of a file to be added are copied. If you want different
    settings, specify them in the options hash:

        $arch->add($logic_path, $stringref,
                   { perm => 0755, uid => 123, gid => 10 });

    If $file\_or\_stringref is a reference to a Unicode string, the `binmode`
    option has to be set to make sure the string gets written as proper UTF-8
    into the tarfile:

        $arch->add($logic_path, $stringref, { binmode => ":utf8" });

- **$arch->remove($logic\_path)**

    Removes a file from the tarball. `$logic_path` is the virtual path
    of the file within the tarball.

- **$arch->locate($logic\_path)**

    Finds the physical location of a file, specified by `$logic_path`, which
    is the virtual path of the file within the tarball. Returns a path to
    the temporary file `Archive::Tar::Wrapper` created to manipulate the
    tarball on disk.

- **$arch->write($tarfile, $compress)**

    Write out the tarball by tarring up all temporary files and directories
    and store it in `$tarfile` on disk. If `$compress` holds a true value,
    compression is used.

- **$arch->tardir()**

    Return the directory the tarball was unpacked in. This is sometimes useful
    to play dirty tricks on `Archive::Tar::Wrapper` by mass-manipulating
    unpacked files before wrapping them back up into the tarball.

- **$arch->is\_gnu()**

    Checks if the tar executable is a GNU tar by running 'tar --version'
    and parsing the output for "GNU".

    Returns true or false (in Perl terms).

- **$arch->is\_bsd()**

    Same as `is_gnu()`, but for BSD.

# Using RAM Disks

On Linux, it's quite easy to create a RAM disk and achieve tremendous
speedups while untarring or modifying a tarball. You can either
create the RAM disk by hand by running

    # mkdir -p /mnt/myramdisk
    # mount -t tmpfs -o size=20m tmpfs /mnt/myramdisk

and then feeding the ramdisk as a temporary directory to
Archive::Tar::Wrapper, like

    my $tar = Archive::Tar::Wrapper->new( tmpdir => '/mnt/myramdisk' );

or using Archive::Tar::Wrapper's built-in option 'ramdisk':

    my $tar = Archive::Tar::Wrapper->new(
        ramdisk => {
            type => 'tmpfs',
            size => '20m',   # 20 MB
        },
    );

Only drawback with the latter option is that creating the RAM disk needs
to be performed as root, which often isn't desirable for security reasons.
For this reason, Archive::Tar::Wrapper offers a utility functions that
mounts the ramdisk and returns the temporary directory it's located in:

      # Create new ramdisk (as root):
    my $tmpdir = Archive::Tar::Wrapper->ramdisk_mount(
        type => 'tmpfs',
        size => '20m',   # 20 MB
    );

      # Delete a ramdisk (as root):
    Archive::Tar::Wrapper->ramdisk_unmount();

Optionally, the `ramdisk_mount()` command accepts a `tmpdir` parameter
pointing to a temporary directory for the ramdisk if you wish to set it
yourself instead of letting Archive::Tar::Wrapper create it automatically.

# KNOWN LIMITATIONS

- Currently, only `tar` programs supporting the `z` option (for
compressing/decompressing) are supported. Future version will use
`gzip` alternatively.
- Currently, you can't add empty directories to a tarball directly.
You could add a temporary file within a directory, and then
`remove()` the file.
- If you delete a file, the empty directories it was located in
stay in the tarball. You could try to `locate()` them and delete
them. This will be fixed, though.
- Filenames containing newlines are causing problems with the list
iterators. To be fixed.
- If you ask Archive::Tar::Wrapper to add a file to a tarball, it copies it into
a temporary directory and then calls the system tar to wrap up that directory
into a tarball.

    This approach has limitations when it comes to file permissions: If the file to
    be added belongs to a different user/group, Archive::Tar::Wrapper will adjust
    the uid/gid/permissions of the target file in the temporary directory to
    reflect the original file's settings, to make sure the system tar will add it
    like that to the tarball, just like a regular tar run on the original file
    would. But this will fail of course if the original file's uid is different
    from the current user's, unless the script is running with superuser rights.
    The tar program by itself (without Archive::Tar::Wrapper) works differently:
    It'll just make a note of a file's uid/gid/permissions in the tarball (which it
    can do without superuser rights) and upon extraction, it'll adjust the
    permissions of newly generated files if the -p option is given (default for
    superuser).

# BUGS

Archive::Tar::Wrapper doesn't currently handle filenames with embedded
newlines.

## Microsoft Windows support

Support on Microsoft Windows is limited.

Version below Windows 10 will not be supported for desktops, and for servers from Windows 2012 and above.

The GNU `tar.exe` program doesn't work properly with the current interface of Archive::Tar::Wrapper.
You must use the `bsdtar.exe` and make sure it appears first in the `PATH` environment variable than
the GNU tar (if it is installed). See [http://libarchive.org/](http://libarchive.org/) for details about how to download and
install `bsdtar.exe`, or go to [http://gnuwin32.sourceforge.net/packages.html](http://gnuwin32.sourceforge.net/packages.html) for a direct download.

Windows 10 might come already with bsdtar program installed. Check 
[https://blogs.technet.microsoft.com/virtualization/2017/12/19/tar-and-curl-come-to-windows/](https://blogs.technet.microsoft.com/virtualization/2017/12/19/tar-and-curl-come-to-windows/) for 
more details.

Having spaces in the path string to the tar program might be an issue too. Although there is some effort
in terms of workaround it, you best might avoid it completely by installing in a different path than
`C:\Program Files`.

# LEGALESE

This software is copyright (c) 2005 of Mike Schilli.

Archive-Tar-Wrapper is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

Archive-Tar-Wrapper is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Archive-Tar-Wrapper. If not, see &lt;http://www.gnu.org/licenses/>.

# AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>

# MAINTAINER

2018, Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>
