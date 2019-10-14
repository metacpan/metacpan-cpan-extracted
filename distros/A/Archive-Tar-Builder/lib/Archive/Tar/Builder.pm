package Archive::Tar::Builder;

# Copyright (c) 2019, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use XSLoader ();

use Archive::Tar::Builder::UserCache     ();
use Archive::Tar::Builder::HardlinkCache ();

our $VERSION = '2.5005';

XSLoader::load( 'Archive::Tar::Builder', $VERSION );

sub archive {
    my ( $self, @members ) = @_;

    die('No paths to archive specified') unless @members;

    return $self->archive_as( map { $_ => $_ } @members );
}

__END__

=head1 NAME

Archive::Tar::Builder - Stream tarball data to a file handle

=head1 DESCRIPTION

Archive::Tar::Builder is meant to quickly and easily generate tarball streams,
and write them to a given file handle.  Though its options are few, its flexible
interface provides for a number of possible uses in many scenarios.

Archive::Tar::Builder supports path inclusions and exclusions, arbitrary file
name length, and the ability to add items from the filesystem into the archive
under an arbitrary name.

=head1 CONSTRUCTOR

=over

=item C<Archive::Tar::Builder-E<gt>new(%opts)>

Create a new Archive::Tar::Builder object.  The following options are honored:

=over

=item C<block_factor>

Specifies the size of the read and write buffer maintained by
Archive::Tar::Builder in multiples of 512 bytes.  Default value is 20.

=item C<quiet>

When set, warnings encountered when reading individual files are not reported.

=item C<ignore_errors>

When set, non-fatal errors raised while archiving individual files do not
cause Archive::Tar::Builder to die() at the end of the stream.

=item C<follow_symlinks>

When set, symlinks encountered while archiving are followed.

=item C<preserve_hardlinks>

When set, hardlinks encountered while archiving are preserved, and their
respective file contents will not be duplicated in the output stream.

=item C<gnu_extensions>

When set, support for arbitrarily long pathnames is enabled using the GNU
LongLink format.

=item C<posix_extensions>

When set, PAX format archives will be streamed.

=back

=back

=head1 FILE PATH MATCHING

File path matching facilities exist to control, based on filenames and patterns,
which data should be included into and excluded from an archive made up of a
broad selection of files.

Note that file pattern matching operations triggered by usage of inclusions and
exclusions are performed against the names of the members of the archive as they
are added to the archive, not as the names of the files as they live in the
filesystem.

=head2 FILE PATH INCLUSIONS

File inclusions can be used to specify patterns which name members that should
be included into an archive, to the exclusion of other members.  File inclusions
take lower precedence to L<exclusions|FILE PATH EXCLUSIONS>.

=over

=item C<$archive-E<gt>include($pattern)>

Add a file match pattern, whose format is specified by fnmatch(3), for which
matching member names should be included into the archive.  Will die() upon
error.

=item C<$archive-E<gt>include_from_file($file)>

Import a list of file inclusion patterns from a flat file consisting of newline-
separated patterns.  Will die() upon error, especially failure to open a file
for reading inclusion patterns.

=back

=head2 FILE PATH EXCLUSIONS

=over

=item C<$archive-E<gt>exclude($pattern)>

Add a pattern which specifies that an exclusion of files and directories with
matching names should be excluded from the archive.  Note that exclusions take
higher priority than inclusions.  Will die() upon error.

=item C<$archive-E<gt>exclude_from_file($file)>

Add a number of patterns from a flat file consisting of exclusion patterns
separated by newlines.  Will die() upon error, especially when unable to open a
file for reading.

=back

=head2 TESTING EXCLUSIONS

=over

=item C<$archive-E<gt>is_excluded($path)>

Based on the file exclusion and inclusion patterns (respectively), determine if
the given path is to be excluded from the archive upon writing.

=back

=head1 WRITING ARCHIVE DATA

=over

=item C<$archive-E<gt>set_handle($handle)>

Set the output file handle to C<$handle>.  This method must be called once prior
to archiving file data.

=item C<$archive-E<gt>archive_as(%files)>

Write a tar stream of ustar format, with GNU tar extensions for supporting long
filenames and other POSIX extensions for files >8GB.  C<%files> should contain
key/value pairs listing the names of files and directories as they exist on the
filesystem, with values being the names the caller wishes said members to be
represented as in the archive.

Files will be included or excluded based on any possible previous usage of the
filename inclusion and exclusion calls.
Returns the total number of bytes written.

=item C<$archive-E<gt>archive(@files)>

Similar to above, however no filename substitution is performed when archiving
members.

=back

=head1 CLEANING UP

=over

=item C<$archive-E<gt>flush()>

Flush the output stream.

=item C<$archive-E<gt>finish()>

Flush the output stream, and die() if any errors were recorded, and the option
C<ignore_errors> is not enabled.  Finally, reset any other error data present.

=back

=head1 AUTHOR

Written by Alexandra Hrefna Maheu <xan@cpan.org>

=head1 CONTRIBUTORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2019, cPanel, L.L.C.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See L<perlartistic> for further details.
