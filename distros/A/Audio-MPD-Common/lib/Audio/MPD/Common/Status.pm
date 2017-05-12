#
# This file is part of Audio-MPD-Common
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Audio::MPD::Common::Status;
# ABSTRACT: class representing MPD status
$Audio::MPD::Common::Status::VERSION = '2.003';
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Bool Int Str };

use Audio::MPD::Common::Time;
use Audio::MPD::Common::Types;


# -- public attributes


has audio          => ( ro, isa=>Str  );
has bitrate        => ( ro, isa=>Int  );
has error          => ( ro, isa=>Str  );
has playlist       => ( ro, isa=>Int  );
has playlistlength => ( ro, isa=>Int  );
has random         => ( ro, isa=>Bool );
has repeat         => ( ro, isa=>Bool );
has songid         => ( ro, isa=>Int  );
has song           => ( ro, isa=>Int  );
has state          => ( ro, isa=>'State' );
has time           => ( ro, isa=>'Audio::MPD::Common::Time', coerce );
has updating_db    => ( ro, isa=>Int  );
has volume         => ( ro, isa=>Int  );
has xfade          => ( ro, isa=>Int, default=>0 );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::MPD::Common::Status - class representing MPD status

=head1 VERSION

version 2.003

=head1 DESCRIPTION

The MPD server maintains some information on its current state. Those
information can be queried with mpd modules. Some of those information
are served to you as an L<Audio::MPD::Common::Status> object.

An L<Audio::MPD::Common::Status> object does B<not> update itself
regularly, and thus should be used immediately.

Note: one should B<never> ever instantiate an L<Audio::MPD::Common::Status>
object directly - use the mpd modules instead.

=head1 ATTRIBUTES

=head2 $status->audio;

A string with the sample rate of the song currently playing, number of
bits of the output and number of channels (2 for stereo) - separated
by a colon.

=head2 $status->bitrate;

The instantaneous bitrate in kbps.

=head2 $status->error;

May appear in special error cases, such as when disabling output.

=head2 $status->playlist;

The playlist version number, that changes every time the playlist
is updated.

=head2 $status->playlistlength;

The number of songs in the playlist.

=head2 $status->random;

Whether the playlist is read randomly or not.

=head2 $status->repeat;

Whether the song is repeated or not.

=head2 $status->song;

The offset of the song currently played in the playlist.

=head2 $status->songid;

The song id (MPD id) of the song currently played.

=head2 $status->state;

The state of MPD server. Either C<play>, C<stop> or C<pause>.

=head2 $status->time;

An L<Audio::MPD::Common::Time> object, representing the time elapsed /
remainging and total. See the associated pod for more details.

=head2 $status->updating_db;

An integer, representing the current update job.

=head2 $status->volume;

The current MPD volume - an integer between 0 and 100.

=head2 $status->xfade;

The crossfade in seconds.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
