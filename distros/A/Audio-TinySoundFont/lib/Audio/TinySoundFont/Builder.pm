package Audio::TinySoundFont::Builder;

use v5.14;
use warnings;
our $VERSION = '0.11';

use Carp;

use Moo;
use Types::Standard qw/ArrayRef HashRef InstanceOf/;

has soundfont => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont'],
  required => 1,
);

has play_script => (
  is      => 'rwp',
  isa     => ArrayRef,
  default => sub { [] },
  coerce  => \&_coerce_play_script,
);

*SAMPLE_RATE = \&Audio::TinySoundFont::XS::SAMPLE_RATE;

sub _coerce_play_script
{
  my $new_script = shift;

  croak "play_script requires an ArrayRef"
      if ref $new_script ne 'ARRAY';

  my @result;
  foreach my $item (@$new_script)
  {
    croak "Script items must be a HashRef, not: " . ref $item
        if ref $item ne 'HASH';

    push @result, {
      in_seconds => ( $item->{in_seconds} // 1 ) + 0,
      at         => ( $item->{at}         // 0 ) + 0,
      for        => ( $item->{for}        // 1 ) + 0,
      note       => ( $item->{note}       // 60 ) + 0,
      vel        => ( $item->{vel}        // 0.5 ) + 0,
      preset     => ( $item->{preset}     // '' ),
    };
  }

  return \@result;
}

sub clear
{
  my $self = shift;

  $self->set( [] );

  return;
}

sub set
{
  my $self   = shift;
  my $script = shift;

  $self->_set_play_script($script);

  return;
}

sub add
{
  my $self   = shift;
  my $script = shift;

  croak "add requires an ArrayRef"
      if ref $script ne 'ARRAY';

  my $old_script = $self->play_script;
  $self->_set_play_script( [ @$old_script, @$script ] );

  return;
}

sub render
{
  my $self = shift;
  my %args = @_;

  my $vol = $args{volume} // $self->soundfont->db_to_vol( $args{db} );

  my $old_vol;
  if ( defined $vol )
  {
    $old_vol = $self->soundfont->volume;
    $self->soundfont->volume($vol);
  }

  my $script = $self->play_script;
  my $SR     = $self->SAMPLE_RATE;
  my $result = '';

  croak "Cannot process play_script when TinySoundFont is active"
      if $self->soundfont->is_active;

  # Create a specialized structure to create a rendering:
  # [ timestamp, fn, preset, note, vel ]
  my @insrs;
  foreach my $item (@$script)
  {
    my $at = $item->{at};
    my $to = $at + $item->{for};
    if ( $item->{in_seconds} )
    {
      $at *= $SR;
      $to *= $SR;
    }
    push @insrs, [ int $at, 'note_on',  @$item{qw/preset note vel/} ];
    push @insrs, [ int $to, 'note_off', @$item{qw/preset note vel/} ];
  }

  @insrs = sort { $a->[0] <=> $b->[0] } @insrs;

  my $current_ts = 0;
  my $soundfont  = $self->soundfont;
  my $tsf        = $soundfont->_tsf;
  foreach my $i ( 0 .. $#insrs )
  {
    my ( $ts, $fn, @args ) = @{ $insrs[$i] };
    $result .= $tsf->render( $ts - $current_ts );
    $soundfont->$fn(@args);
    $current_ts = $ts;
  }

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

Audio::TinySoundFont::Builder - Construct SoundFont audio by description of play events.

=head1 SYNOPSIS

  use Audio::TinySoundFont;
  my $tsf = Audio::TinySoundFont->new('soundfont.sf2');
  my $builder = $tsf->new_builder(
    [
      {
        preset => 'Clarinet',
        note   => 59,
        at     => 0,
        for    => 2,
      },
    ]
  );
  $builder->add(
    [
      {
        preset     => $preset,
        note       => 60,
        at         => 44100,
        for        => 44100 * 2,
        in_seconds => 0,
      },
    ]
  );
  my $samples = $builder->render;

=head1 DESCRIPTION

Audio::TinySoundFont::Builder can be used to automate the creation of audio
samples by describing the events by what times that notes should be turned on
and their duration.

=head1 CONSTRUCTOR

Audio::TinySoundFont::Builder is not constructed manually, instead you get an
instance from the L<preset|Audio::TinySoundFont/new_builder> method of
L<Audio::TinySoundFont>.

=head1 METHODS

=head2 soundfont

  my $tsf = $builder->soundfont;

The L<Audio::TinySoundFont> object that this Preset object was created from.

=head2 play_script

  my $script = $builder->play_script;

The current script that is ready to generate. The play_script is an ArrayRef
of HashRefs, each defining a single event. See L</add> for details of the
events.

NOTE: This structure should only be read, not modified. To make modifications,
use L</set> or L</add>.

=head2 clear

  $builder->clear;

Clear the play_script.

=head2 add

  $builder->add( [ @script_items ] );

Add a list of events to the play_script. Each event HashRef can have the
following keys, all other keys will be ignored.

=over

=item in_seconds

A boolean to indicate if C<at> and C<for> are expressed in seconds or samples.
If it is true, which is the default, C<at> and C<for> will be interpreted as
seconds.

=item at

A number that indicates when to trigger the L<note_on|Audio::TinySoundFont/note_on>
call. If C<in_seconds> is true, this number will be taken as seconds, otherwise
it will be number of samples. The default is to start at 0.

=item for

A number that indicates when to trigger the L<note_off|Audio::TinySoundFont/note_off>
call. If C<in_seconds> is true, this number will be taken as seconds, otherwise
it will be number of samples. The default is to end at 1, which if C<in_seconds>
is false, will probably not be what you want.

=item note

The MIDI note number to activate which will be passed to L<note_on|Audio::TinySoundFont/note_on>
and L<note_off|Audio::TinySoundFont/note_off>. The default is 60, which is
Middle C.

=item vel

The note velocity floating point number between 0.0 and 1.0 that will be passed
to L<note_on|Audio::TinySoundFont/note_on>. The default is 0.5.

=item preset

The preset to activate which will be passed to L<note_on|Audio::TinySoundFont/note_on>
and L<note_off|Audio::TinySoundFont/note_off>. It can be a preset name or a
L<Preset|Audio::TinySoundFont::Preset> object. The default is '', which is
likely not what you want because it is unlikely to exist.

=back

=head2 set

  $builder->set( [ @script_items ] );

Replaces the play_script with a new list of events. See L</add> for the format
of the event HashRef.

=head2 render
=head2 render_unpack

  my $samples = $builder->render( %options );
  my @samples = $builder->render_unpack( %options );

Returns a string of 16-bit, little endian sound samples for the play_script
using TinySoundFont. The result can be unpacked using C<unpack("s<*")>
or you can call L</render_unpack> instead to get an array. It accepts an
options hash that allow you to customize how the sound should be generated.

This method cannot be used if the L</soundfont> has any
L<active voices|Audio::TinySoundFont/is_active> and will croak if that is the
case.

=over

=item volume

The general volume of the returned sample, expressed as a float between 0.0 and
1.0. If both L</volume> and L</db> are given, volume will be used.

=item db

The volume of the sample, expressed in as a logarithmic dB float between -100
and 0, with -100 being equivalent to silent and 0 being as loud as TinySoundFont
can go.  If both L</volume> and L</db> are given, volume will be used.

=back

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

L<Audio::TinySoundFont>, L<TinySoundFont|https://github.com/schellingb/TinySoundFont>

=cut
