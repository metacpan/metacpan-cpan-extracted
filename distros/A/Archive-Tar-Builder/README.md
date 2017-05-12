# NAME

Archive::Tar::Builder - Stream tarball data to a file handle

# DESCRIPTION

Archive::Tar::Builder is meant to quickly and easily generate tarball streams,
and write them to a given file handle.  Though its options are few, its flexible
interface provides for a number of possible uses in many scenarios.

Archive::Tar::Builder supports path inclusions and exclusions, arbitrary file
name length, and the ability to add items from the filesystem into the archive
under an arbitrary name.

# CONSTRUCTOR

- `Archive::Tar::Builder->new(%opts)`

    Create a new Archive::Tar::Builder object.  The following options are honored:

    - `block_factor`

        Specifies the size of the read and write buffer maintained by
        Archive::Tar::Builder in multiples of 512 bytes.  Default value is 20.

    - `quiet`

        When set, warnings encountered when reading individual files are not reported.

    - `ignore_errors`

        When set, non-fatal errors raised while archiving individual files do not
        cause Archive::Tar::Builder to die() at the end of the stream.

    - `follow_symlinks`

        When set, symlinks encountered while archiving are followed.

    - `gnu_extensions`

        When set, support for arbitrarily long pathnames is enabled using the GNU
        LongLink format.

# FILE PATH MATCHING

File path matching facilities exist to control, based on filenames and patterns,
which data should be included into and excluded from an archive made up of a
broad selection of files.

Note that file pattern matching operations triggered by usage of inclusions and
exclusions are performed against the names of the members of the archive as they
are added to the archive, not as the names of the files as they live in the
filesystem.

## FILE PATH INCLUSIONS

File inclusions can be used to specify patterns which name members that should
be included into an archive, to the exclusion of other members.  File inclusions
take lower precedence to [exclusions](https://metacpan.org/pod/FILE&#x20;PATH&#x20;EXCLUSIONS).

- `$archive->include($pattern)`

    Add a file match pattern, whose format is specified by fnmatch(3), for which
    matching member names should be included into the archive.  Will die() upon
    error.

- `$archive->include_from_file($file)`

    Import a list of file inclusion patterns from a flat file consisting of newline-
    separated patterns.  Will die() upon error, especially failure to open a file
    for reading inclusion patterns.

## FILE PATH EXCLUSIONS

- `$archive->exclude($pattern)`

    Add a pattern which specifies that an exclusion of files and directories with
    matching names should be excluded from the archive.  Note that exclusions take
    higher priority than inclusions.  Will die() upon error.

- `$archive->exclude_from_file($file)`

    Add a number of patterns from a flat file consisting of exclusion patterns
    separated by newlines.  Will die() upon error, especially when unable to open a
    file for reading.

## TESTING EXCLUSIONS

- `$archive->is_excluded($path)`

    Based on the file exclusion and inclusion patterns (respectively), determine if
    the given path is to be excluded from the archive upon writing.

# WRITING ARCHIVE DATA

- `$archive->set_handle($handle)`

    Set the output file handle to `$handle`.  This method must be called once prior
    to archiving file data.

- `$archive->archive_as(%files)`

    Write a tar stream of ustar format, with GNU tar extensions for supporting long
    filenames and other POSIX extensions for files >8GB.  `%files` should contain
    key/value pairs listing the names of files and directories as they exist on the
    filesystem, with values being the names the caller wishes said members to be
    represented as in the archive.

    Files will be included or excluded based on any possible previous usage of the
    filename inclusion and exclusion calls.
    Returns the total number of bytes written.

- `$archive->archive(@files)`

    Similar to above, however no filename substitution is performed when archiving
    members.

# CLEANING UP

- `$archive->flush()`

    Flush the output stream.

- `$archive->finish()`

    Flush the output stream, and die() if any errors were recorded, and the option
    `ignore_errors` is not enabled.  Finally, reset any other error data present.

# AUTHOR

Written by Xan Tronix <xan@cpan.org>

# CONTRIBUTORS

- Rikus Goodell <rikus.goodell@cpanel.net>
- Brian Carlson <brian.carlson@cpanel.net>

# COPYRIGHT

Copyright (c) 2014, cPanel, Inc.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See [perlartistic](https://metacpan.org/pod/perlartistic) for further details.
