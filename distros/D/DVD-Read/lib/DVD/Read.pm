package DVD::Read;

use 5.010000;
use strict;
use warnings;
use AutoLoader;
use vars qw($AUTOLOAD);
use Carp;

use DVD::Read::Dvd;
use DVD::Read::Title;
use DVD::Read::Dvd::Ifo::Vmg;

our $VERSION = '0.04';

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;
    if (exists(${DVD::Read::Dvd::}{$sub})) {
        return $self->{dvd}->$sub(@args);
    } else {
        croak("No function DVD::Read::$sub");
    }
}

sub DESTROY {}

=head1 NAME

DVD::Read - libdvdread perl binding

=head1 SYNOPSIS

  use DVD::Read;
  my $dvd = DVD::Read->new('/dev/cdrom');
  print $dvd->volid;
  print "\n";
  foreach (1 .. $dvd->titles_count) {
    print "$_ : ";
    print $dvd->title_chapters_count($_);
    print " chapters\n";
    my $title = $dvd->get_title($_);
    # ...
  }

=head1 DESCRIPTION

This module provide way to query video DVD using libdvdread.

=head2 Dvd Structure

  Dvd (device, directory, iso file...)
  |
  \_ VMG (VIDEO_VTS.IFO)
     ` title_one => title1 (chapters map)
     ` title_two => title2 (chapters map)
     ` ...
  |
  \_ VTS title1 (VIDEO_1_VTS.IFO)
     ` audio track 1
     ` audio track 2
     ` audio track ...
     ` subtitle track 1
     ` subtitle track 2
     ` subtitle track ...
     ` chapters location in VOB
  |
  \_ VTS title2 (VIDEO_2_VTS.IFO)
  \_ VTS title...

=head2 This Module

=over 4

=item The DVD and VGM information are provide by DVD::Read module.

=item The VTS (per title) are provide by L<DVD::Read::Title> module.

=back

=head2 Technical Notes

=head3 Video Sector

The 'first_sector' and 'last_sector' from module can disagree with
'tcprobe' (from transcode) results.

After wasting some times to look the code, it seems 'tcprobe' code wrong.

In a nutshell, Title is made of chapter, chapter point to first cells,
each cells have a first and last sector. But a chapter can have severals
cells. This is what is used by lsdvd to count cells.

'tcprobe' assume each chapter have only one cells, then fetch cells[chapter]
to get sectors number. Which is wrong, according 'lsdvd' code.

Notice both VGM and VTS are often need to get title information.
This module will transparently fetch information need to retrieve
information you want.

=head2 PERFORMANCE NOTICE

You have two way to fetch title object:

    my $dvd = DVD::Read->new('/dev/crom');
    my $title = $dvd->get_title(1);
    # or in another way
    my $title = DVD::Read::Title->new($dvd, 1);

or by calling directly the DVD::Read::Title module
with a location:

    my $title = DVD::Read::Title->new('/dev/cdrom', 1);

Notice in the second case, calling another title will force to
read again the main information table (if need) because the
DVD::Read object will not be transmitted, so another will be created.

This can be important when using real DVD reader device since waking
up it can take time.

=head1 FUNCTIONS

=cut

=head2 new($device)

Return a new DVD::Read object for $device. $device can either
a real device, an iso image file, a directory, or anything supported
by libdvdread:

 * If the path given is a directory, then the files in that directory may be
 * in any one of these formats:
 *
 *   path/VIDEO_TS/VTS_01_1.VOB
 *   path/video_ts/vts_01_1.vob
 *   path/VTS_01_1.VOB
 *   path/vts_01_1.vob

=cut

sub new {
    my ($class, $device) = @_;

    my $dvd = DVD::Read::Dvd->new($device) or return;

    bless({
        device => $device,
        dvd => $dvd,
        vmg => undef,
        vts => [],
    }, $class);
}

sub _vmg {
    my ($self) = @_;
    return $self->{vmg} ||= DVD::Read::Dvd::Ifo::Vmg->new($self->{dvd});
}

=head2 volid

Return the volume identifier from ISO9660 format.
Works only from a device or iso image.

=head2 titles_count

Return the count of title on the DVD

=cut

sub titles_count {
    my ($self) = @_;
    $self->_vmg or return;
    return $self->_vmg->titles_count;
}

=head2 title_chapters_count($title)

Return the chapters count for title number $title.

=cut

sub title_chapters_count {
    my ($self, $titleno) = @_;
    $self->_vmg or return;
    return $self->_vmg->title_chapters_count($titleno);
}

=head2 title_angles_count($title)

Return the number of angle for title number $title

=cut

sub title_angles_count {
    my ($self, $titleno) = @_;
    $self->_vmg or return;
    return $self->_vmg->title_angles_count($titleno);
}

=head2 get_title($title)

Return a DVD::Read::Title object for title number $title

=cut

sub get_title {
    my ($self, $titleno) = @_;
    return if ($titleno > $self->titles_count);
    return $self->{vts}[$titleno] ||=
        DVD::Read::Title->new($self, $titleno);
}

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

=item L<DVD::Read::Title>

=back

Theses modules are provided but are low level access:

=over 4

=item L<DVD::Read::Dvd>

=item L<DVD::Read::Dvd::Ifo>

=back

=head1 AUTHOR

Olivier Thauvin E<lt>nanardon@nanardon.zarb.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The libdvdread is under the GPL Licence.
