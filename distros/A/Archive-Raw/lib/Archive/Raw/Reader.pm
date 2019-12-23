package Archive::Raw::Reader;
$Archive::Raw::Reader::VERSION = '0.02';
use strict;
use warnings;
use Archive::Raw;

=head1 NAME

Archive::Raw::Context - libarchive Reader class

=head1 VERSION

version 0.02

=head1 DESCRIPTION

A L<Archive::Raw::Reader> represents a reader

=head1 METHODS

=head2 new( )

Create a new reader.

=head2 open_filename( $archive_filename)

Open the C<$filename> on disk.

=head2 has_encrypted_entries( )

Check if the archive has encrypted entries.

=head2 format_capabilities( )

Get a bitmask of the capabilities supported by the archive.

=head2 add_passphrase( $phrase )

Add a decryption passphrase.

=head2 close( )

Close the file and release most resources.

=head2 next( )

Parse and return the next entry header. Returns a L<C<Archive::Raw::Entry>> object.

=head2 format( )

Get the archive format.

=head2 format_name( )

Get a textual representation of the archive format.

=head2 file_count( )

Get the numer of files processed so far.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Archive::Raw::Reader
