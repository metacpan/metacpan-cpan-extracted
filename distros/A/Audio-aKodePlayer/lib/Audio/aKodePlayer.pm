package Audio::aKodePlayer;

use warnings;
use strict;

use 5.008;
use strict;
use warnings;
use Carp;

=head1 NAME

Audio::aKodePlayer - A simple Perl interface to the aKode audio library.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
require XSLoader;
XSLoader::load('Audio::aKodePlayer', $VERSION);

use constant {
  CLOSED  => 0,
  OPEN    => 2,
  LOADED  => 4,
  PLAYING => 8,
  PAUSED  => 12
};

sub isClosed {
  my $self = shift;
  return ($self->state == CLOSED) ? 1 : 0;
}

sub isOpen {
  my $self = shift;
  return ($self->state == OPEN)  ? 1 : 0;
}

sub isLoaded {
  my $self = shift;
  return ($self->state == LOADED)  ? 1 : 0;
}

sub isPlaying {
  my $self = shift;
  return ($self->state == PLAYING) ? 1 : 0;
}

sub isPaused {
  my $self = shift;
  return ($self->state == PAUSED) ? 1 : 0;
}

1;
__END__

=head1 DESCRIPTION

This module provides a simple interface to the aKode::Player class
from the C++ aKode library. aKode is a simple audio-decoding
frame-work that provides a uniform interface to decode the most common
audio-formats such as WAV, MP3, Ogg/Vorbis, Ogg/FLAC, etc.  It also
has a direct playback option for a number of audio-outputs, such as
OSS, Alsa, SunOS/Solaris audio, Jack, and Polyp (recommended for
network transparent audio).

=head1 SYNOPSIS

  use Audio::aKodePlayer;

  my $player = Audio::aKodePlayer->new();
  $player->open('auto'); # automatically selected output sink
  $player->load( 'my_audio.ogg' ); # any format supported by aKode
  $player->play();
  $player->seek(10*1000) if $player->seekable; # seek 10 seconds from the beginning
  while (!$player->eof) {
    print "Playback position: ".($player->position()/1000)." seconds of ".($player->length()/1000)."\n";
    sleep 1;
  }
    ...
  $player->pause();
  $player->resume();
  $player->setVolume(0.75);
  print "Current volume is at ".($player->volume()*100)."%\n";
    ...
  $player->wait;   # idle until the playback stops
  $player->stop;   # stop playback
  $player->unload; # release resources related to the media
  $player->close;  # release resources related to the the output sink


=head1 EXPORT

None.

=cut

=head1 FUNCTIONS

=over 4

=item new()

Create a new Audio::aKodePlayer object.

=item open(sinkname)

Opens a player that outputs to the sink sinkname (the sink 'auto' is
recommended, other options are 'alsa', 'jack', 'oss', 'polyp', 'sun',
and maybe other, depending on the aKode installation).

Returns false if the device cannot be opened.

=item close()

Closes the player and releases the output sink.

=item load(filename)

Loads the file from a given filename and prepares it for
playing. Returns false if the file cannot be loaded or decoded.

=item setDecoderPlugin(plugin_name)

Sets the decoder plugin to use. Default is auto-detect.

=item setResamplerPlugin(plugin_name)

Sets the resampler plugin to use. Default is "fast".

=item Audio::aKodePlayer::listPlugins()

Returns the names of available plugins (as an array).

=item Audio::aKodePlayer::listSinks()

Returns the names of available sinks (as an array).

=item Audio::aKodePlayer::listDecoders()

Returns the names of available decoders (as an array).

=item unload()

Unload the file and release any resources allocated while loaded.

=item play()

Start playing.

=item stop()

Stop playing and release any resources allocated while playing.

=item wait()

Waits for the file to finish playing (eof or error) and calls
stop. This blocks the calling thread.

=item detach()

Detach the player from the current thread (once detached, you won't be
able to apply any methods on the player object).

=item pause()

Pause the player.

=item resume()

Resume the player from paused.

=item setVolume(volume)

Set the software-volume. Use a number between 0.0 and 1.0.

=item volume()

Returns the current value of the software-volume.

=item state ()

Returns the current state of the Player, as a number.  The constants
Audio::aKodePlayer::CLOSED, Audio::aKodePlayer::OPEN,
Audio::aKodePlayer::LOADED, Audio::aKodePlayer::PLAYING, and
Audio::aKodePlayer::PAUSED can be used, but it is recommended to use
directly the methods isClosed, isOpen, isLoaded, isPlaying, and
isPaused instead.

=item seek(milliseconds)

Attempts a seek to pos milliseconds into the file/stream. Returns true if succesfull.

=item length()

Returns the length of the file/stream in milliseconds. Returns -1 if the length is unknown.

WARNING: current version of aKode (2.0.1) returns lenghts in seconds for WAV files.

=item position()

Returns the current position in file/stream in milliseconds. Returns -1 if the position is unknown.

WARNING: current version of aKode (2.0.1) returns position in seconds for WAV files.

=item seekable()

Returns true if the decoder is seekable.

=item eof()

Returns true if the decoder has reached the end-of-file/stream.

=item decoderError()

Returns true if the decoder has encountered a non-recoverable error.

=item setSampleRate(rate)

Sets the output sample-rate on the resampler to a given value. (May not
work with all sinks.)

=item setSpeed(value)

Sets the resample speed to a given value.
(May not work with all sinks.)

=item isClosed ()

Return true if the player is in the closed state.

=item isOpen ()

Return true if the player is in the open state.

=item isLoaded ()

Return true if the player is in the Loaded state.

=item isPlaying ()

Return true if the player is in the playing state.

=item isPaused ()

Return true if the player is in the paused state.

=back

=head1 CAVEATS

The C++ class provides a method aKode::Player::open(FILE), where FILE
is an overloaded class derived from the aKode::File interface. This
allows for streaming. The current bindings do not have interface for
this feature. Feel free to submit a patch.

=head1 KNOWN BUGS

Current version of aKode (2.0.1) probably contains a bug, so
position() and length() are reported in seconds rather than in
milliseconds for WAV files.

=head1 AUTHOR

Petr Pajas, C<< <pajas at matfyz.cz> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-audio-akodeplayer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-aKodePlayer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audio::aKodePlayer

You can also look for information at:

=over 4

=item * aKode project

L<http://carewolf.com/akode/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-aKodePlayer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-aKodePlayer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-aKodePlayer>

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-aKodePlayer>

=back

=head1 ACKNOWLEDGEMENTS

aKode library was written Allan Sandfeld.

The Perl bindings were written by Petr Pajas L<http://pajas.matfyz.cz>
and their development was supported by the grant no. 1ET101120503 of
the Grant Agency of Academy of Sciences of the Czech Republic.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Petr Pajas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Audio::aKodePlayer
