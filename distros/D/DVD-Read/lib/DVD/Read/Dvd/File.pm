package DVD::Read::Dvd::File;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

use DVD::Read::Dvd;

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);

=head1 NAME

DVD::Read::Dvd::File - DVD file access using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  my file = DVD::Read::Dvd::File->new($dvd, 1, "VOB");
  
=head1 DESCRIPTION

This module allow to get information from Video DVD using
by using the dvdread library.

=head1 CONSTANTS

=head2 BLOCK_SIZE

Return the logical DVD block size

=head1 FUNCTIONS

=head2 new($dvd, $num, $type)

Open a file from the DVD.

=over 4

=item $dvd is a L<DVD::Read::Dvd> object over the dvd device

=item $num is the file or title number to open

=item $type is the file type to open:

=over 4

=item IFO VIDEO_TS.IFO or VTS_XX_0.IFO (title)

=item BUP VIDEO_TS.BUP or VTS_XX_0.BUP (title)

=item MENU VIDEO_TS.VOB or VTS_XX_0.VOB (title)

=item VOB VTS_XX_[1-9].VOB (title).  All files in
the title set are opened and read as a single file. 

=back

=back

=head2 size

Return the file size in blocks

=head2 readblock($offset, $count)

Read a $count block(s) from the file at block offset $offset.

In scalar context, return the read data.

In array context return the count of blocks read and read data.

=cut

1;

__END__

=head1 CAVEAT

Most of C code come from mplayer and transcode (tcprobe).

Thanks authors of these modules to provide it as free software.

As this software are under another license, and this module reuse
code from it, the Perl license is maybe not appropriate.

Just mail me if this is a problem.

=head1 SEE ALSO

=over 4

=item L<DVD::Read::Dvd>

=back

=head1 AUTHOR

Olivier Thauvin E<lt>nanardon@nanardon.zarb.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The libdvdread is under the GPL Licence.
