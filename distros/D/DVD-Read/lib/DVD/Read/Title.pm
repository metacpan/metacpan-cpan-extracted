package DVD::Read::Title;

use 5.010000;
use strict;
use warnings;

use DVD::Read;
use DVD::Read::Dvd::Ifo::Vts;
use DVD::Read::Dvd::File;
use AutoLoader;
use vars qw($AUTOLOAD);
use Carp;

our $VERSION = '0.04';

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;
    if (exists(${DVD::Read::Dvd::Ifo::Vts::}{"vts_$sub"})) {
        $sub = "vts_$sub";
        return $self->_vts->$sub(@args);
    } elsif (exists(${DVD::Read::Dvd::Ifo::Vts::}{$sub}) && $sub =~ /^chapter_/) {
        my ($chapter) = (@args);
        $self->_vts->$sub(
            $self->_vmg->title_ttn($self->{titleid}),
            $chapter,
        );
    } else {
        croak("No function DVD::Read::Title::$sub");
    }
}

sub DESTROY {}

=head1 NAME

DVD::Read::Title - Fetch information from DVD video.

=head1 SYNOPSIS

  use DVD::Read::Title;
  my $title = DVD::Read::Title->new('/dev/cdrom', 1);
  print $title->video_format_txt . "\n";

=head1 DESCRIPTION

Fetch information from DVD video title.

=head1 FUNCTIONS

=head2 new($dvd, $title)

Return a new DVD::Read::Title object for $dvd and title number
$title.

$dvd can be either a string for IFO location, or a DVD::Read object.

=cut

sub new {
    my ($class, $dvd, $title) = @_;

    my $dvdobj = ref $dvd
        ? $dvd
        : DVD::Read->new($dvd);

    my $self = bless({
        titleid => $title,
        dvd => $dvdobj,
        vts => undef,
    }, $class);

    $self->_vts or return;

    $dvdobj->{vts}[$title] = $self;
}

sub _dvd {
    my ($self) = @_;
    return $self->{dvd}
}

sub _vmg {
    my ($self) = @_;
    return $self->_dvd->_vmg;
}

sub _vts {
    my ($self) = @_;
    $self->_vmg or return;
    my $nr = $self->title_nr or return;
    return $self->{vts} ||=
        DVD::Read::Dvd::Ifo::Vts->new($self->_dvd->{dvd}, $nr);
}

=head2 chapter_first_sector($chapter)

Return the first sector for chapter number $chapter

=head2 chapter_last_sector($chapter)

Return the last sector for chapter number $chapter

=head2 chapter_offset($chapter)

Return the chapter offset from the start of title in millisecond

=cut

=head2 length

The length in millisecond of this title.

=cut

sub length {
    my ($self) = @_;
    $self->_vmg or return;
    $self->_vts->title_length(
        $self->_vmg->title_ttn($self->{titleid}),
    );
}

=head2 chapters_count

Return the chapters count for this title

=cut

sub chapters_count {
    my ($self) = @_;
    $self->_vmg or return;
    $self->_vmg->title_chapters_count($self->{titleid});
}

=head2 title_nr

Return the real title number physically on dvd.

=cut

sub title_nr {
    my ($self) = @_;
    $self->_vmg or return;
    $self->_vmg->title_nr($self->{titleid});
}

=head2 extract($out, $progress)

Copy video data for the wall title into $out where:

$out is either a file path or an open file handle

$progress, if set, is a function reference accepting four args:
the current cells count read and total cells count to read, the current
block read for the cell, the total block for current cell.
This allow you to show the current read progress.

=cut

sub extract {
    my ($self, $outf, $progress) = @_;

    $progress ||= sub {};

    my $out;
    if (ref $outf eq 'GLOB') {
        $out = $outf;
    } else {
        open ($out, '>', $outf) or return;
    }

    my $pgc = $self->pgc(
        $self->pgc_id($self->_vmg->title_ttn($self->{titleid}), 1) || 0
    ) or return;

    my $dvdfile = DVD::Read::Dvd::File->new(
        $self->_dvd->{dvd},
        $self->title_nr,
        'VOB',
    ) or return;

    my $count = 0;
    my $cells_count = $pgc->cells_count;
    foreach my $cellid (
        map { $pgc->cell_number($_) }
        (1 .. $cells_count)) {
        my $cell = $pgc->cell($cellid);
        foreach my $sector ($cell->first_sector .. $cell->last_sector) {
            $progress->($cellid -1, $cells_count, $sector - $cell->first_sector,
            $cell->last_sector - $cell->first_sector +1); 
            my ($co, $data) = $dvdfile->readblock($sector, 1);
            $co or return;
            $count += $co;
            print $out $data;
        }
        $progress->($cellid, $cells_count, 0, 0);
    }

    if (ref $outf ne 'GLOB') {
        close($out);
    }

    return $count;
}

=head2 extract_chapter($chapter, $out, $progress)

Copy video data for chapter $chapter into $out where:

$out is either a file path or an open file handle

$chapter either the chapter number to extract or an array of chapters
to extract.

$progress, if set, is a function reference acception four args:
the current chapter count read, the count of chapter to read,
the current block count read in for current chapter, the count
of block to read for the current chapter.
This allow you to give a progression status.

=cut

sub extract_chapter {
    my ($self, $chapter, $outf, $progress) = @_;

    $progress ||= sub {};

    my $out;
    if (ref $outf eq 'GLOB') {
        $out = $outf;
    } else {
        open ($out, '>', $outf) or return;
    }

    my @chapters = ref $chapter eq 'ARRAY'
        ? @{ $chapter }
        : ($chapter);

    my $dvdfile = DVD::Read::Dvd::File->new(
        $self->_dvd->{dvd},
        $self->title_nr,
        'VOB',
    ) or return;

    my $count = 0;
    my $chapter_count = 0;
    foreach my $ch (@chapters) {

        defined(my $fs = $self->chapter_first_sector($ch)) or return;
        defined(my $ls = $self->chapter_last_sector($ch))  or return;
        foreach($fs .. $ls) {
            $progress->($chapter_count, scalar(@chapters),
                        $_ - $fs, $ls - $fs);
            my ($co, $data) = $dvdfile->readblock($_, 1);
            $count += $co;
            print $out $data;
        }
        $chapter_count++;
        #finalyze
        $progress->($chapter_count, scalar(@chapters), 0, 0);
    }

    if (ref $outf ne 'GLOB') {
        close($out);
    }

    $count;
}

=head1 AUTOLOADED FUNCTIONS

All functions from L<DVD::Read::Dvd::IFO> module starting by 'vts_'
are available (without 'vts_' prefix).

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

=item L<DVD::Read>

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
