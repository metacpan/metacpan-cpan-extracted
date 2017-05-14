#!/usr/bin/env perl

#       Audacious.pm - A Perl interface to Audacious
#       Copyright 2010 Alexandria Wolcott <alyx@woomoo.org>

#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are
#       met:
#
#       * Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#       * Redistributions in binary form must reproduce the above
#         copyright notice, this list of conditions and the following disclaimer
#         in the documentation and/or other materials provided with the
#         distribution.
#       * Neither the name of the Alexandria Wolcott nor the names of its
#         contributors may be used to endorse or promote products derived from
#         this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#       A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Audio::Audacious;
use strict;
use warnings;
use Carp qw(croak);
use Method::Signatures;

method new($class: ) {
    my $self = bless {}, $class;
    return $self;
}

method current {
    my $title = `audtool2 current-song-tuple-data title`;
    chomp($title);
    my $artist = `audtool2 current-song-tuple-data artist`;
    chomp($artist);
    my $album = `audtool2 current-song-tuple-data album`;
    chomp($album);
    my $genre = `audtool2 current-song-tuple-data genre`;
    chomp($genre);
    my $bitrate = `audtool2 current-song-tuple-data bitrate`;
    chomp($bitrate);
    my $file = `audtool2 current-song-tuple-data file-path`;
    chomp($file);
    my $length = `audtool2 current-song-length`;
    chomp($length);

    my $event = {
        'title'    => $title,
        'artist'   => $artist,
        'album'   => $album,
        'genre'   => $genre,
        'file'    => $file,
        'length'  => $length,
        'bitrate' => $bitrate
    };
    return $event;
}

method next {
    `audtool2 playlist-advance`;
    return $self->current;
}

method back {
    `audtool2 playlist-reverse`;
    return $self->current;
}

method add {
    my $url = $_[1];
    `audtool2 playlist-addurl $url`;
    return 1;
}

method listlength {
    my $length = `audtool2 playlist-length`;
    chomp($length);
    return $length;
}

method display {
    my $playlist = `audtool2 playlist-display`;
    my @pl = split( "\n", $playlist );
    return @pl;
}

method  position {
    my $position = `audtool2 playlist-position`;
    chomp($position);
    return $position;
}

method jump {
    my $position = $_[1];
    `audtool2 playlist-jump $position`;
    return $self->current;
}

method clear {
    `audtool2 playlist-clear`;
    return 1;
}

method repeat {
    my $toggle = $_[1];
    if ($toggle) {
        `audtool2 playlist-repeat-toggle $toggle`;
        return 1;
    }
    else {
        my $status = `audtool2 playlist-repeat-status`;
        chomp($status);
        return $status;
    }
}

method shuffle {
    my $toggle = $_[1];
    if ($toggle) {
        `audtool2 playlist-shuffle-toggle $toggle`;
        return 1;
    }
    else {
        my $status = `audtool2 playlist-shuffle-status`;
        chomp($status);
        return $status;
    }
}

method playlist {
    my $name = `audtool2 current-playlist-name`;
    chomp($name);
    return $name;
}

method play {
    `audtool2 playback-play`;
    return $self->current;
}

method pause {
    `audtool2 playback-pause`;
    return 1;
}

method stop {
    `audtool2 playback-stop`;
    return 1;
}

method get_volume {
    my $volume = `audtool2 get-volume`;
    chomp($volume);
    return $volume;
}

method set_volume {
    my $volume = $_[1];
    `audtool2 set-volume $volume`;
    return 1;
}

method eq {
    my $param = $_[1];
    if ($param) {
            if ( $param =~ /(Y|1|on)/i )  { $param = 'yes'; }
            elsif ( $param =~ /(N|0|off)/i ) { $param = 'no'; }
            else { return 0; }
        `audtool2 equalizer-activate $param`;
        return 1;
    }
    else {
        my $eq = `audtool2 equalizer-get`;
        chomp($eq);
        return $eq;
    }
}

method version {
    my $version = `audtool2 version`;
    chomp($version);
    return $version;
}

1;

__END__

=head1 NAME

Audacious - An Object-orientated interface to Audacious

=head1 VERSION

Version 0.92

=head1 SYNOPSIS

General usage:

  use strict;
  use warnings;
  use Audacious;

  my $aud = Audacious->new();

  my $volume = $aud->get_volume;
  print("Current Audacious volume is $volume\n");

  $aud->set_volume(80);

=head1 DESCRIPTION

This module provides a clean OOP interface to the Audacious media player, via interfacing with `audtool2`.

=head1 OBJECT INTERFACE

=head2 CONSTRUCTOR

=over

=item C<new>

Creates a new Audacious object.

=back

=head2 METHODS

=over

=item C<current>

Returns a hashref of the current song and related info.

HASHREF: {
          'bitrate' => '200',
          'length' => '5:20',
          'album' => 'Discovery',
          'artist' => 'Daft Punk',
          'file' => 'file:///usr/home/alyx/Music/Music/Daft Punk/Discovery/',
          'title' => 'One More Time',
          'genre' => 'Electronic'
        };


=item C<next>

Go to the next song in the playlist. Returns the new current song.


=item C<back>

Go to the previous song in the playlist. Returns the new current song.


=item C<add>

Add a URL to the playlist.



=item C<listlength>

Returns the total length of the playlist (In minutes)



=item C<position>

Returns the current position in the playlist.



=item C<jump>

Jump to the specified position in the playlist. Returns the new current song.



=item C<clear>

Clears the playlist.



=item C<repeat>

If given a parameter, will toggle the repeat setting of Audacious.
If called without a parameter, will return the current repeat setting.



=item C<shuffle>

If given a parameter, will toggle the shuffle setting of Audacious.
If called without a parameter, will return the current shuffle setting.



=item C<playlist>

Returns the name of the current playlist.



=item C<play>

Starts song playback.



=item C<pause>

Pauses/Unpauses song playback.



=item C<stop>

Stops song playback.



=item C<get_volume>

Returns the current volume level.



=item C<set_volume>

Sets volume to the given parameter.



=item C<eq>

If given a parameter, will toggle the equaliser to that parameter.
If not parameter is given, will return the current equaliser setting.



=item C<version>

Returns Audacious' version.

=back


=head1 AUTHOR

Alexandria Wolcott <alyx@woomoo.org>


=head1 LICENSE

Copyright E<copy> Alexandria Wolcott

This module may be used, modified, and distributed under BSD license. See the beginning of this file for said license.

=head1 SEE ALSO

L<http://hg.atheme.org/audacious>
