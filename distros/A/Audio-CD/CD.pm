package Audio::CD;

use strict;
use DynaLoader ();

{
    no strict;
    $VERSION = '0.04';
    @ISA = qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION);
}

1;
__END__

=head1 NAME

Audio::CD - Perl interface to libcdaudio (cd + cddb)

=head1 SYNOPSIS

  use Audio::CD ();
  my $cd = Audio::CD->init;

=head1 DESCRIPTION

Audio::CD provides a Perl interface to libcdaudio by Tony Arcieri,
available from http://cdcd.undergrid.net/

Several classes provide glue for the libcdaudio functions and data
structures.

=head1 Audio::CD Class

=over 4

=item init

Initialize the Audio::CD object:

 my $cd = Audio::CD->init;

=item stat

Stat the I<Audio::CD> object, returns an I<Audio::CD::Info> object.

 my $info = $cd->stat;

=item cddb

Returns an I<Audio::CDDB> object.

 my $cddb = $cd->cddb;

=item play

Play the given cd track (defaults to 1).

 $cd->play(1);

=item stop

Stop the cd.

 $cd->stop;

=item pause

Pause the cd.

 $cd->pause;

=item resume

Resume the cd.

 $cd->resume;

=item eject

Eject the cd.

 $cd->eject;

=item close

Close the cd tray.

 $cd->close;

=item play_frames

 $cd->play_frames($startframe, $endframe);

=item play_track_pos

 $cd->play_track_pos($strarttrack, $endtrack, $startpos);

=item play_track

 $cd->play_track($strarttrack, $endtrack);

=item track_advance

 $cd->track_advance($endtrack, $minutes, $seconds);

=item advance

 $cd->advance($minutes, $seconds);

=item get_volume

Returns an I<Audio::CD::Volume> object.

 my $vol = $cd->get_volume;

=item set_volume

 $cd->set_volume($vol);

=back

=head1 Audio::CDDB Class

=over 4

=item discid

 my $id = $cddb->discid;

=item lookup

Does a cddb lookup and returns an I<Audio::CD::Data> object.

 my $data = $cddb->lookup;

=back

=item Audio::CD::Data Class

=over 4

=item artist

 my $artist = $data->artist;

=item title

 my $title = $data->title;

=item genre

 my $genre = $data->genre;

=item tracks

Returns an array reference of I<Audio::CD::Track> objects.

=back

=head1 Audio::CD::Track Class

=over 4

=item name

 my $name = $track->name;

=back

=head1 Audio::CD::Info Class

=over 4

=item mode

Returns the CD mode, one of PLAYING, PAUSED, COMPLETED, NOSTATUS;

 my $track = $info->mode;
 print "playing" if $info->mode == Audio::CD::PLAYING;

=item total_tracks

Returns the total number of tracks on the cd.

 my $track = $info->total_tracks;

=item track_time

Returns the current track play time:

 my($minutes, $seconds) = $info->track_time;

=item time

Returns the current disc play time:

 my($minutes, $seconds) = $info->time;

=item length

Returns the disc length time:

 my($minutes, $seconds) = $info->length;

=item tracks

Returns an array reference of I<Audio::CD::Info::Track> objects.

=back


=head1 Audio::CD::Info::Track Class

=over 4

=item length

Returns the track length time:

 my($minutes, $seconds) = $tinfo->length;

=item pos

Returns the track position on the CD:

 my($minutes, $seconds) = $tinfo->pos;

=item type

Returns the track type (either TRACK_AUDIO or TRACK_DATA):

 if ($tinfo->type == Audio::CD::TRACK_AUDIO) {
   print "audio track\n";
 } elsif ($tinfo->type == Audio::CD::TRACK_DATA) {
   print "data track\n";
 }


=item is_audio

Returns true if the track is an audio track; equivalent to the test:

 $tinfo->type == Audio::CD::TRACK_AUDIO ? 1 : 0

=item is_data

Returns true if the track is a data track; equivalent to the test:

 $tinfo->type == Audio::CD::TRACK_DATA ? 1 : 0

=back


=head1 SEE ALSO

Xmms(3)

=head1 AUTHOR

Perl interface by Doug MacEachern

libcdaudio and cddb_lookup.c by Tony Arcieri

