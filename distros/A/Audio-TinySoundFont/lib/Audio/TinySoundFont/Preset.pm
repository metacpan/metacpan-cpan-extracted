package Audio::TinySoundFont::Preset;

use v5.14;
use warnings;
our $VERSION = '0.12';

use autodie;
use Carp;
use Try::Tiny;
use Moo;
use Types::Standard qw/Int Str InstanceOf/;

has soundfont => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont'],
  required => 1,
);

has index => (
  is       => 'ro',
  isa      => Int,
  required => 1,
);

has name => (
  is      => 'ro',
  isa     => Str,
  lazy    => 1,
  builder => sub
  {
    my $self = shift;
    $self->soundfont->_tsf->get_presetname( $self->index ) // '';
  },
);

sub render
{
  my $self = shift;
  my %args = @_;

  my $tsf = $self->soundfont->_tsf;

  croak "Cannot render a preset when TinySoundFont is active"
      if $tsf->active_voices;

  my $SR      = $tsf->SAMPLE_RATE;
  my $seconds = $args{seconds} // 0;
  my $samples = ( $seconds * $SR ) || $args{samples} // $SR;
  my $note    = $args{note} // 60;
  my $vel     = $args{vel} // 0.5;
  my $vol     = $args{volume} // $self->soundfont->db_to_vol( $args{db} );

  my $old_vol;
  if ( defined $vol )
  {
    $old_vol = $self->soundfont->volume;
    $self->soundfont->volume($vol);
  }

  my $vel_msg = qq{Velocity of "$vel" should be between 0 and 1};
  if ( $vel < 0 )
  {
    carp qq{$vel_msg, setting to 0};
    $vel = 0;
  }

  if ( $vel > 1 )
  {
    carp qq{$vel_msg, setting to 1};
    $vel = 1;
  }

  my $note_msg = qq{Note "$note" should be between 0 and 127};
  if ( $note < 0 )
  {
    carp qq{$note_msg, setting to 0};
    $note = 0;
  }

  if ( $note > 127 )
  {
    carp qq{$note_msg, setting to 127};
    $note = 127;
  }

  $tsf->note_on( $self->index, $note, $vel );

  my $result = $tsf->render($samples);
  $tsf->note_off( $self->index, $note );

  my $cleanup_samples = 4096;
  for ( 1 .. 256 )
  {
    last
        if !$tsf->active_voices;
    $result .= $tsf->render($cleanup_samples);
  }

  if ( defined $old_vol )
  {
    $self->soundfont->volume($old_vol);
  }

  return $result;
}

sub render_unpack
{
  my $self = shift;

  return unpack( 's<*', $self->render(@_) );
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::TinySoundFont::Preset - SoundFont Preset Represntation

=head1 SYNOPSIS

  use Audio::TinySoundFont;
  my $preset = $tsf->preset('Clarinet');
  my $audio  = $preset->render(seconds => 5, note => 59, vel => 0.7, volume => .3);

=head1 DESCRIPTION

Audio::TinySoundFont::Preset is a Preset, or musical sample in the SoundFont
nomenclature. It is the largest usable building block in a SoundFont and
generally represents a single instrument.

=head1 CONSTRUCTOR

Audio::TinySoundFont::Preset is not constructed manually, instead you get an
instance from the L<preset|Audio::TinySoundFont/preset> or L<preset_index|Audio::TinySoundFont/preset_index> methods of L<Audio::TinySoundFont>.

=head1 METHODS

=head2 soundfont

The L<Audio::TinySoundFont> object that this Preset object was created from.

=head2 index

The index of this preset in the SoundFont file.

=head2 name

The name of the preset. For example, it could be "Clarinet", "Accordion",
"Standard Drums" or "Sine Wave".

=head2 render

  my $samples = $preset->render(%options);

Returns a string of 16-bit, little endian sound samples for this
preset using TinySoundFont. The result can be unpacked using C<unpack("s<*")>
or you can call L</render_unpack> function to get an array instead. It accepts
several options that allow you to customize how the sound should be generated.

This method cannot be used if the L</soundfont> is currently playing anything
and will croak if that is the case.

=head3 options

=over

=item seconds

This sets how long the preset should be played for, from Attack to Release.
It defaults to 1 second. If both L</seconds> and L</samples> are given,
seconds will be used.

NOTE: The sample is not constrained to the number of seconds given, it is the
minimum number of seconds that will be returned. The sound may continue to
play after these many seconds, and often will, because of the decay phase
of the SoundFont.

=item samples

This is an alternative way to set how long the preset should be played for,
from Attack to Release, measure in 16-bit samples. It defaults to 1 second
worth of samples. If both L</seconds> and L</samples> are given, seconds will
be used.

NOTE: The sample is not constrained to the number of samples given, it is the
minimum number of samples that will be returned. The sound may continue to
play after these many samples, and often will, because of the decay phase
of the SoundFont.

=item note

This is the MIDI note to be played with 60 meaning middle C, which is the
default. It is an integer between 0 and 127.

=item vel

The MIDI velocity of the note played, expressed as a float between 0 and 1,
the default is 0.5. Generally a velocity causes a louder noise to be played,
but the SoundFont can use it modify other aspects of the sound. This is
separate from L</volume> which controls the general volume of the resulting
sample.

=item volume

The general volume of the sample, expressed as a float between 0 and 1.
If both L</volume> and L</db> are given, volume will be used.

=item db

The volume of the sample, expressed in as a dB float between -100 and 0, with
-100 being equivalent to silent and 0 being as loud as TinySoundFont can go.
If both L</volume> and L</db> are given, volume will be used.

=back

=head2 render_unpack

  my @samples = $preset->render_unpack(%options);

Returns an array of of 16-bit sound samples for this preset using TinySoundFont.
All of the options are identical to L</render>.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

L<Audio::TinySoundFont>, L<TinySoundFont|https://github.com/schellingb/TinySoundFont>.

=cut
