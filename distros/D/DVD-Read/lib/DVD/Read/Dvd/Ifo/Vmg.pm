package DVD::Read::Dvd::Ifo::Vmg;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);
use DVD::Read::Dvd::Ifo;

=head1 NAME

DVD::Read::Dvd::Ifo::Vmg - Access to DVD VMG file using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  use DVD::Read::Dvd::Ifo::Vmg;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  my $vmg = DVD::Read::Dvd::Ifo::Vmg->new($dvd);
  ...

=head1 DESCRIPTION

This module provide a low level access DVD IFO files
using libdvdread for the Vmg information.

This module allow you to get video titles informations
step by step like it is done by libdvdread.

Notice functions provided by module are really basics, then
you really need to understand the dvd information to use it.

=head1 GENERICS FUNCTIONS

=cut

=head2 new($dvd, $id)

Return a new DVD::Read::Dvd::Ifo::Vmg from $dvd.

$dvd should be L<DVD::Read::Dvd> object.

=cut

sub new {
    my ($class, $dvd) = @_;
    my $vts = DVD::Read::Dvd::Ifo->new($dvd, 0);
    bless($vts, $class);
}

=head2 vmg_identifier

Return the vmg_identifier

=head2 titles_count

Return the count of titles on the DVD

=head2 title_angles_count($title)

Get the angle count for title number $title

=head2 title_chapters_count($title)

Return the count of chapters for title number $title

=head2 title_nr($title)

Return the internal title id for title number $title.

The VGM provide the ordered list of title on DVD, which is usually
different of the physical order.

Here a real example to get title 1:

    my $vgm = DVD::Read::Dvd::Ifo($dvd, 0);
    my $titlenr = $vgm->title_nr(1);
    $chapter_count = $vgm->title_chapters_count($titlenr);
    my vts = DVD::Read::Dvd::Ifo($dvd, $titlenr);

    ...

=head2 title_ttn($title)

Return the title track number for title number $title.

Eg: the video number inside the video number 'title_nr'.

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
=item L<DVD::Read::Dvd::Ifo>
=item L<DVD::Read::Dvd::Ifo::Vts>

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
