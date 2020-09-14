# NAME

Archive::Tar::Wrapper - API wrapper around the 'tar' utility

# SYNOPSIS

```perl
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
```

# DESCRIPTION

`Archive::Tar::Wrapper` is an API wrapper around the `tar` command line
program. It never stores anything in memory, but works on temporary
directory structures on disk instead. It provides a mapping between
the logical paths in the tarball and the 'real' files in the temporary
directory on disk.

It differs from `Archive::Tar` in two ways:

* `Archive::Tar::Wrapper` doesn't hold anything in memory. Everything is
stored on disk.
* `Archive::Tar::Wrapper` is 100% compliant with the platform's `tar`
utility, because it uses it internally.

# DOCUMENTATION

Be sure to check out the POD documentation available with the distribution!

# KNOWN LIMITATIONS

* Currently, only `tar` programs supporting the `z` option (for
compressing/decompressing) are supported. Future version will use
`gzip` alternatively.
* Currently, you can't add empty directories to a tarball directly.
You could add a temporary file within a directory, and then
`remove()` the file.
* If you delete a file, the empty directories it was located in
stay in the tarball. You could try to `locate()` them and delete
them. This will be fixed, though.
* Filenames containing newlines are causing problems with the list
iterators. To be fixed.
* If you ask Archive::Tar::Wrapper to add a file to a tarball, it copies it into
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

`Archive::Tar::Wrapper` doesn't currently handle filenames with embedded
newlines.

## Microsoft Windows support

Support on Microsoft Windows is limited.

Version below Windows 10 will not be supported for desktops, and for servers
from Windows 2012 and above.

The GNU `tar.exe` program doesn't work properly with the current interface of
`Archive::Tar::Wrapper`.
You must use the `bsdtar.exe` and make sure it appears first in the `PATH`
environment variable than the GNU tar (if it is installed). See
[http://libarchive.org/](http://libarchive.org/) for details about how to
download and install `bsdtar.exe`, or go to
[http://gnuwin32.sourceforge.net/packages.html](http://gnuwin32.sourceforge.net/packages.html)
for a direct download.

Windows 10 might come already with bsdtar program installed. Check
[https://blogs.technet.microsoft.com/virtualization/2017/12/19/tar-and-curl-come-to-windows/](https://blogs.technet.microsoft.com/virtualization/2017/12/19/tar-and-curl-come-to-windows/)
for more details.

Having spaces in the path string to the `tar` program might be an issue too.
Although there is some effort in terms of workaround it, you best might avoid it
completely by installing in a different path than `C:\Program Files`.

# LEGALESE

This software is copyright (c) 2005 of Mike Schilli.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Archive-Tar-Wrapper. If not, see [http://www.gnu.org/licenses/](http://www.gnu.org/licenses/).

# AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>

# MAINTAINER

2018, Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>
