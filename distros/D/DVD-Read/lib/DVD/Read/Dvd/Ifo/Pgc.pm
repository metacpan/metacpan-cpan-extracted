package DVD::Read::Dvd::Ifo::Pgc;

use 5.010000;
use strict;
use warnings;

use DVD::Read::Dvd::Ifo::Cell;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);

=head1 NAME

DVD::Read::Dvd::Ifo::Pgc - Access to DVD IFO file using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  use DVD::Read::Dvd::Ifo;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  my $vmg = DVD::Read::Dvd::Ifo->new($dvd, 0);
  ...

=head1 DESCRIPTION

This module provide a low level access DVD IFO files
using libdvdread.

The PGC is part of video program from DVD.

=head1 EXPLANATIONS

Title contains severals programs, each programs contains a set of ptr to
cells, each cells point to video sector:

  TITLE (VIDEO_01_VTS.IFO) :
    |- PGC ID1 [.... $pgc_num ..]            <= track number
    |             |       |
    |             `cell1  ` cell3...
    |
    |- PGC ID2 [.... $pgc_num ......]        <= track number
                 |       |        |
                 `cell1  `cell2   `cell3

This module handle one PGC from a title.

=head1 FUNCTIONS

=head2 id

Return the id for this pgc.

=head2 cells_count

Return the count of cells inside this pgn.

=head2 cell_number($pgc_num)

Return the number of the cell for pgn $pgc_num.

=head2 cell($cell_number)

Return the L<DVD::Read::Dvd::Ifo::Cell> number $cell_number.

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
=item L<DVD::Read::Dvd::Vmg>
=item L<DVD::Read::Dvd::Vts>

=back

=head1 AUTHOR

Olivier Thauvin E<lt>nanardon@nanardon.zarb.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The libdvdread is under the GPL Licence.

=cut
