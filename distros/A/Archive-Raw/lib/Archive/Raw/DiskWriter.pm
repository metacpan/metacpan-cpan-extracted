package Archive::Raw::DiskWriter;
$Archive::Raw::DiskWriter::VERSION = '0.02';
use strict;
use warnings;
use Archive::Raw;

=head1 NAME

Archive::Raw::DiskWriter - libarchive DiskWriter class

=head1 VERSION

version 0.02

=head1 DESCRIPTION

A L<Archive::Raw::DiskWriter> represents a diskwriter

=head1 METHODS

=head2 new( )

Create a new disk writer.

=head2 write( $entry )

Write C<$entry> to disk. C<$entry> should be an L<C<Archive::Raw::Entry>> object.

=head1 AUTHOR

Jacques Germishuys <jacquesg@striata.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jacques Germishuys.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Archive::Raw::DiskWriter
