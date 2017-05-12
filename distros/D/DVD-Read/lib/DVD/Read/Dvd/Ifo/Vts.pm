package DVD::Read::Dvd::Ifo::Vts;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);
use DVD::Read::Dvd::Ifo;
use DVD::Read::Dvd::Ifo::Pgc;
use DVD::Read::Dvd::Ifo::Cell;

=head1 NAME

DVD::Read::Dvd::Ifo::Vts - Access to DVD IFO file using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  use DVD::Read::Dvd::Ifo::Vmg;
  use DVD::Read::Dvd::Ifo::Vts;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  my $vmg = DVD::Read::Dvd::Ifo::Vts::Vmg->new($dvd);
  my $vts = DVD::Read::Dvd::Ifo::Vts::Vts->new(
    $dvd,
    $vmg->title_nr(0),
  );
  ...

=head1 DESCRIPTION

This module provide a low level access DVD IFO files
using libdvdread.

This module allow you to get video titles informations
step by step like it is done by libdvdread.

Notice functions provided by module are really basics, then
you really need to understand the dvd information to use it.

=head1 FUNCTIONS

=cut

=head2 new($dvd, $id)

Return a new DVD::Read::Dvd::Ifo::Vts:

=over 4

=item $dvd

A DVD::Read::Dvd object.

=item $id

The title number you want to get information.

=back

=cut

sub new {
    my ($class, $dvd, $number) = @_;
    $number or return;
    my $vts = DVD::Read::Dvd::Ifo->new($dvd, $number);
    bless($vts, $class);
}

=head2 vts_identifier

A string to identify the VTS

=head2 vts_ttn_count

Return the count of track inside this title.

=head2 vts_chapters_count($ttn)

Return the count of chapter for title number $ttn.

=head2 vts_video_format

Return the video format

=head2 vts_video_format_txt

Return the video format in textual form

=cut

sub vts_video_format_txt {
    my ($self) = @_;
    defined(my $fmt = $self->vts_video_format) or return;
    return [ 'ntsc', 'pal' ]->[$fmt];
}

=head2 vts_video_size

Return the width and height of the video

=head2 vts_video_mpeg_version

Return the MPEG version used

=head2 vts_video_mpeg_version_txt

Return the MPEG version in textual form

=cut

sub vts_video_mpeg_version_txt {
    my ($self) = @_;
    defined(my $mpeg = $self->vts_video_mpeg_version) or return;
    'mpeg' . ($mpeg + 1)
}

=head2 vts_video_aspect_ratio

Return the aspect ratio

=head2 vts_video_aspect_ratio_txt

Return the aspect ratio in textual form

=cut

sub vts_video_aspect_ratio_txt {
    my ($self) = @_;
    defined(my $fmt = $self->vts_video_aspect_ratio) or return;
    return { 0 => '4:3', 3 => '16:9' }->{$fmt};
}

=head2 vts_video_permitted_df

Return the 'permitted_df' value, but no sure about
its meaning

=head2 vts_video_permitted_df_txt

Return the 'permitted_df' in textual form (from
transcode code).

=cut

sub vts_video_permitted_df_txt {
    my ($self) = @_;
    defined(my $fmt = $self->vts_video_permitted_df) or return;
    return [
        'pan&scan+letterboxed',
        'only pan&scan',
        'only letterboxed',
        '',
    ]->[$fmt];
}

=head2 vts_video_film_mode

Return true if the video is a movie

=head2 vts_video_letterboxed

Unknown meaning...

=head2 vts_video_line21_cc_1

Unknown meaning...

=head2 vts_video_line21_cc_2

Unknown meaning...

=head2 vts_video_ntsc_cc

Unknown meaning...

=cut

sub vts_video_ntsc_cc {
    my ($self) = @_;
    if($self->line21_cc_1 && $self->line21_cc_2) {
        return "NTSC CC 1 2";
    } elsif($self->line21_cc_1) {
        return "NTSC CC 1";
    } elsif($self->line21_cc_2) {
        return "NTSC CC 2";
    } else {
        return "";
    }
}

=head2 vts_audios

Return the list of existing audios tracks id

=head2 vts_audio_id($id)

Return the VID of the audio track number $id.

=head2 vts_audio_format($id)

Return the format of audio track number $id.

=head2 vts_audio_format_txt($id)

Return the format of audio track number $id
in textual form.

=cut

sub vts_audio_format_txt {
    my ($self, $audiono) = @_;
    defined(my $val = $self->vts_audio_format($audiono)) or return;
    return {
        0 => 'ac3',
        2 => 'mpeg layer 1/2/3',
        3 => 'mpeg2 ext',
        4 => 'lpcm',
        5 => 'sdds',
        6 => 'dts',
    }->{$val}
}

=head2 vts_audio_frequency($id)

Return the frequency for audio track number $id.

=head2 vts_audio_frequency_txt($id)

Return the frequency for audio track number $id in textual form.

=cut

sub vts_audio_frequency_txt {
    my ($self, $audiono) = @_;
    defined(my $val = $self->vts_audio_frequency($audiono)) or return;
    return [
        '48kHz', '96kHz', '44.1kHz', '32kHz'
    ]->[$val];
}

=head2 vts_audio_language($id)

Return the language code for audio track number $id.

=head2 vts_audio_lang_extension($id)

Return the language extension for audio track number $id.
In fact this is comment about track content.

=head2 vts_audio_lang_extension_txt($id)

Return the language extension for audio track number $id
in textual form.

=cut

sub vts_audio_lang_extension_txt {
    my ($self, $audiono) = @_;
    $self->_lang_extension_txt($self->vts_audio_lang_extension($audiono));
}

=head2 vts_audio_quantization($id)

Not sure about the meaning, should the bit count
used to code sound.

=head2 vts_audio_quantization_txt($id)

Return audio quantization in textual form.

=cut

sub vts_audio_quantization_txt {
    my ($self, $audiono) = @_;
    defined(my $val = $self->vts_audio_quantization($audiono)) or return;
    return [
        '16bit', '20bit', '24bit', 'drc'
    ]->[$val];
}

=head2 vts_audio_channel($id)

Return the channel mode for audio track number $id.

=head2 vts_audio_channel_txt($id)

Return the channel mode for audio track number $id
in textual form.

=cut

sub vts_audio_channel_txt {
    my ($self, $audiono) = @_;
    defined(my $val = $self->vts_audio_channel($audiono)) or return;
    return [
        "mono", "stereo", "unknown", "unknown", 
        "5.1/6.1", "5.1"
    ]->[$val];
}

=head2 vts_audio_appmode($id)

The application mode for audio track number $id.
Eg, is the track for karaoke ?

=head2 vts_audio_appmode_txt($id)

The application mode for audio track number $id
in textual form.

=cut

sub vts_audio_appmode_txt {
    my ($self, $audiono) = @_;
    defined(my $val = $self->vts_audio_appmode($audiono)) or return;
    return [
        '', 'karaoke mode', 'surround sound mode', 
    ]->[$val];
}

=head2 vts_audio_multichannel_extension($id)

Does the audio track number $id has multichannel extension ?

=cut

=head2 vts_subtitles

Return the list of existing subtitles tracks id

=head2 vts_subtitle_id($id) 

Return the VID of subtitle number $id.

=cut

sub vts_subtitle_id {
    my ($self, $id) = @_;
    if (grep { $_ == $id } $self->vts_subtitles) {
        return $id + 0x20;
    } else {
        return;
    }
}

=head2 vts_subtitle_language($id)

Return the language for subtitle $id.

=head2 vts_subtitle_lang_extension($id)

Return the language extension for susbtitle number $id.
This is in fact a comment about the subtitle content.

=head2 vts_subtitle_lang_extension_txt($id)

Return the language extension for susbtitle number $id
in textual form.

=cut

sub vts_subtitle_lang_extension_txt {
    my ($self, $subtitleno) = @_;
    $self->_lang_extension_txt($self->vts_audio_lang_extension($subtitleno));
}

sub _lang_extension_txt {
    my ($self, $code) = @_;
    defined($code) or return;
    return [
        '', 'Normal Caption', 'Audio for visually impaired',
        'Director\'s comments #1', 'Director\'s comments #2',
    ]->[$code];
}

=head2 title_length($ttn)

Return the length in millisecond of title handle by $vts
DVD::Read::Dvd::Ifo object get from a title > 0.

=cut

sub _chapter_lenght {
    my ($self, $ttn, $chapter) = @_;

    my $pgc = $self->vts_pgc(
        $self->vts_pgc_id($ttn, $chapter)
    ) or return;

    my $last_cell_num = $self->_chapter_last_cell_num($ttn, $chapter);

    my $time = 0;
    foreach ($pgc->cell_number($self->vts_pgc_num($ttn, $chapter)) .. $last_cell_num) {
        $time += $pgc->cell($_)->time;
    }
    $time
}

sub _chapter_last_cell_num {
    my ($self, $ttn, $chapter) = @_;

    return if ($ttn > $self->vts_ttn_count);
    my $pgc = $self->vts_pgc(
        $self->vts_pgc_id($ttn, $chapter) || 0
    ) or return;

    $chapter >= $self->vts_chapters_count($ttn)
        ? $pgc->cells_count
        : $pgc->cell_number($self->vts_pgc_num($ttn, $chapter + 1)) - 1;
}

=head2 chapter_offset($title, $chapter)

Return in millisecond the chapter offset from movie start of
chapter number $chapter of title number $title.

$vts is the DVD::Read::Dvd::Ifo object for title number $title.

It is unfriendly to have to give again the title number if the
VTS IFO is given. I haven't find another way, but remember this
module is low level access to dvdread API.

=cut

sub chapter_offset {
    my ($self, $ttn, $chapter) = @_;

    $chapter ||= 1;
    my $offset = 0;
    foreach(1 .. $chapter -1) {
        $offset += $self->_chapter_lenght($ttn, $_);
    }
    $offset
}

=head2 chapter_first_sector($title, $chapter)

Return first sector of chapter $chapter for title $title.

$vts is the DVD::Read::Dvd::Ifo object for title number $title.

=cut

sub chapter_first_sector {
    my ($self, $ttn, $chapter) = @_;

    return if ($ttn > $self->vts_ttn_count);
    return if ($chapter > $self->vts_chapters_count($ttn));

    my $pgc = $self->vts_pgc(
        $self->vts_pgc_id($ttn, $chapter)
    ) or return;

    $pgc->cell(
        $pgc->cell_number(
            $self->vts_pgc_num($ttn, $chapter)
        )
    )->first_sector
}

=head2 chapter_last_sector($title, $chapter)

Return last sector of chapter $chapter for title $title.

$vts is the DVD::Read::Dvd::Ifo object for title number $title.

=cut

sub chapter_last_sector {
    my ($self, $ttn, $chapter) = @_;

    return if ($ttn > $self->vts_ttn_count);
    my $pgc = $self->vts_pgc(
        $self->vts_pgc_id($ttn, $chapter) || 0
    ) or return;

    $pgc->cell(
        $self->_chapter_last_cell_num($ttn, $chapter)
    )->last_sector
}

=head2 vts_pgcs_count

Return the count of pgc in this title.

=head2 vts_pgc_id($ttn, $chapter)

Return the pgc number for title track number $ttn and chapter
number $chapter.

=head2 vts_pgc($pgc_id)

Return the L<DVD::Read::Dvd::Ifo::Pgc> object number $pgc_id.

The $pgc_id is given by vts_pgc_id function.

=head2 vts_pgc_num($ttn, $chapter)

Return inside the pgc, the pgc number containing the cell data.

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
=item L<DVD::Read::Dvd::Ifo::Vmg>

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
