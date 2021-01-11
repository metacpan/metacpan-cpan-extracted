package Audio::TinySoundFont;

use v5.14;
use warnings;
our $VERSION = '0.10';

use autodie;
use Carp;
use Try::Tiny;
use Scalar::Util qw/blessed/;

use Moo;
use Types::Standard qw/ArrayRef HashRef GlobRef Str Int Num InstanceOf/;

use Audio::TinySoundFont::XS;
use Audio::TinySoundFont::Preset;
use Audio::TinySoundFont::Builder;

has _tsf => (
  is       => 'ro',
  isa      => InstanceOf ['Audio::TinySoundFont::XS'],
  required => 1,
);

has volume => (
  is      => 'rw',
  isa     => Num,
  default => 0.3,
  trigger => sub { my $self = shift; $self->_tsf->set_volume(shift) },
);

has preset_count => (
  is  => 'lazy',
  isa => Int,
);

has presets => (
  is  => 'lazy',
  isa => HashRef,
);

*SAMPLE_RATE = \&Audio::TinySoundFont::XS::SAMPLE_RATE;

my $XS        = 'Audio::TinySoundFont::XS';
my %ref_build = (
  '' => sub
  {
    my $file = shift;
    croak qq{File "$file" doesn't exist}
        if !-e $file;
    return try { $XS->load_file($file) } catch { croak $_ };
  },
  SCALAR => sub
  {
    my $str = shift;
    open my $glob, '<', $str;
    return try { $XS->load_fh($glob) } catch { croak $_ };
  },
  GLOB => sub
  {
    my $fh = shift;
    return try { $XS->load_fh($fh) } catch { croak $_ };
  },
);

sub BUILDARGS
{
  my $class = shift;
  my $file  = shift;
  my $args  = Moo::Object::BUILDARGS( $class, @_ );

  my $build_fn = $ref_build{ ref $file };
  croak "Cannot load soundfont file, unknown ref: " . ref($file)
      if !defined $build_fn;
  my $tsf = $build_fn->($file);
  $args->{volume} = 0.3;

  $args->{_tsf} = $tsf;

  return $args;
}

sub _build_preset_count
{
  my $self = shift;

  return $self->_tsf->presetcount;
}

sub _build_presets
{
  my $self = shift;

  my %result;
  foreach my $i ( 0 .. $self->preset_count )
  {
    my $name     = $self->_tsf->get_presetname($i) // '';
    my $n        = '';
    my $conflict = 1;
    while ( exists $result{"$name$n"} )
    {
      $conflict++;
      $n = "_$conflict";
    }
    $name = "$name$n";
    $result{$name} = Audio::TinySoundFont::Preset->new(
      soundfont => $self,
      index     => $i,
    );
  }

  return \%result;
}

sub preset
{
  my $self = shift;
  my $name = shift;

  my $preset = $self->presets->{$name};

  croak qq{Could not find preset "$name"}
      if !defined $preset;

  return $preset;
}

sub preset_index
{
  my $self  = shift;
  my $index = shift;

  croak qq{Could not find preset "$index"}
      if $index >= $self->preset_count;

  return Audio::TinySoundFont::Preset->new(
    soundfont => $self,
    index     => $index,
  );
}

sub new_builder
{
  my $self   = shift;
  my @script = @_;

  if ( @script == 1 && ref $script[0] eq 'ARRAY' )
  {
    @script = @{ $script[0] };
  }

  return Audio::TinySoundFont::Builder->new(
    soundfont   => $self,
    play_script => \@script,
  );
}

sub active_voices
{
  my $self = shift;
  return $self->_tsf->active_voices;
}

sub is_active
{
  my $self = shift;
  return !!$self->_tsf->active_voices;
}

sub note_on
{
  my $self   = shift;
  my $preset = shift // croak "Preset is required for note_on";
  my $note   = shift // 60;
  my $vel    = shift // 0.5;

  if ( !blessed $preset )
  {
    $preset = $self->preset($preset);
  }

  ( InstanceOf ['Audio::TinySoundFont::Preset'] )->($preset);

  $self->_tsf->note_on( $preset->index, $note, $vel );
  return;
}

sub note_off
{
  my $self   = shift;
  my $preset = shift // croak "Preset is required for note_off";
  my $note   = shift // 60;

  if ( !blessed $preset )
  {
    $preset = $self->preset($preset);
  }

  ( InstanceOf ['Audio::TinySoundFont::Preset'] )->($preset);

  $self->_tsf->note_off( $preset->index, $note );
  return;
}

sub render
{
  my $self = shift;
  my %args = @_;

  my $tsf = $self->_tsf;

  my $SR      = $tsf->SAMPLE_RATE;
  my $seconds = $args{seconds} // 0;
  my $samples = ( $seconds * $SR ) || $args{samples} // $SR;

  return $tsf->render($samples);
}

sub render_unpack
{
  my $self = shift;

  return unpack( 's<*', $self->render(@_) );
}

sub db_to_vol
{
  my $self = shift;
  my $db   = shift;

  return
      if !defined $db;

  # Volume is a float 0.0-1.0, db is in dB -100..0, so adjust it to a float
  $db
      = $db > 0    ? 0
      : $db < -100 ? -100
      :              $db;
  return 10**( $db / 20 );
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::TinySoundFont - Interface to TinySoundFont, a "SoundFont2 synthesizer library in a single C/C++ file"

=head1 SYNOPSIS

  use Audio::TinySoundFont;
  my $tsf = Audio::TinySoundFont->new('soundfont.sf2');
  $tsf->note_on( 'Clarinet', 60, 1.0 );
  my $samples = $tsf->render( seconds => 5 );
  my $preset = $tsf->preset('Clarinet');
  $tsf->note_off( $preset, 60 );
  $samples .= $tsf->render( seconds => 5 );
  
  # Using the Preset object
  my $preset = $tsf->preset('Clarinet');
  my $samples = $preset->render(
    seconds => 5,
    note => 60,
    vel => 0.7,
    volume => .3,
  );
  
  # Using the Builder object
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

Audio::TinySoundFont is a wrapper around L<TinySoundFont|https://github.com/schellingb/TinySoundFont>,
a "SoundFont2 synthesizer library in a single C/C++ file". This allows you to
load a SoundFont file and synthesize samples from it.

=head1 CONSTRUCTOR

=head2 new

  my $tsf = Audio::TinySoundFont->new($soundfont_file, %attributes)

Construct a new Audio::TinySoundFont object using the provided C<$soundfont_file>
file. It can be a filename, a file handle, or a string reference to the contents
of a SoundFont.

=head3 Attributes

=over

=item volume

Set the initial, global volume. This is a floating point number between 0.0 and
1.0. The higher the number, the louder the output samples.

=back

=head1 METHODS

=head2 volume

  my $volume = $tsf->volume;
  $tsf->volume( 0.5 );

Get or set the current global volume. This is a floating point number between
0.0 and 1.0. The higher the number, the louder the output samples.

=head2 preset_count

  my $count = $tsf->preset_count;

The number of presets available in the SoundFont.

=head2 presets

  my %presets = %{ $tsf->presets }

A HashRef of all of the presets in the SoundFont. The key is the name of the
preset and the value is the L<Audio::TinySoundFont::Preset> object for that
preset.

=head2 preset

  my $preset = $tsf->preset('Clarinet');

Get a L<Audio::TinySoundFont::Preset> object by name. This will croak if the
preset name is not found.

=head2 preset_index

  my $preset = $tsf->preset_index($index);

Get an L<Audio::TinySoundFont::Preset> object by index in the SoundFont. This
will croak if the index is out of range. Note, this will return a different
object than L</preset> will, which will return the object from L<presets>.

=head2 SAMPLE_RATE

  my $sample_rate = $tsf->SAMPLE_RATE

Returns the sample rate that TinySoundFont is operating on, expressed as hertz
or samples per second. This is currently static and is 44_100;

=head2 new_builder

  my $builder = $tsf->new_builder

Create a new L<Audio::TinySoundFont::Builder> object. This can be used to
generate a single sample from a script of what notes to play when.

=head2 active_voices

  my $count = $tsf->active_voices;

Returns the number of currently active voices that TinySoundFont is rendering.
Generally speaking, each L</note_on> will make one or more voices active.

=head2 is_active

  my $bool = $tsf->is_active

Returns if TinySoundFont currently has active voices and will output audio
during render.

=head2 note_on

  $tsf->note_on($preset, $note, $velocity);

Turns a note on for a Preset. C<$preset> can either be a
L<Audio::TinySoundFont::Preset> object or the name of a Preset. Both C<$note>
and C<$velocity> are optional. C<$note> is a MIDI note between 0 and 127, with
60 being middle C and the default if it is not given. C<$velocity> is a floating
point number between 0.0 and 1.0 with the default being 0.5.

=head2 note_off

  $tsf->note_off($preset, $note);

Turns a note off for a Preset. C<$preset> can either be a
L<Audio::TinySoundFont::Preset> object or the name of a Preset. C<$note> is
optional and is the same MIDI note given on L</note_on>. The default is 60.
This will not immediately stop a note from playing, it will begin the note's
release phase.

=head2 render

  my $samples = $tsf->render( seconds => 5 );
  my $samples = $tsf->render( samples => 44_100 );

Returns a string of 16-bit, little endian sound samples using TinySoundFont of
the specified length. The result can be unpacked using C<unpack("s<*")> or you
can call L</render_unpack> function to get an array instead. This will return
the exact number of samples requested; calling L</render> 5 times at 1 second
each is identical to calling L</render> once for 5 seconds.

=over

=item seconds

This sets how many samples to generate in terms of seconds. The default is 1
second. If both L</seconds> and L</samples> are given, seconds will be used.

=item samples

This sets how many samples to generate in terms of seconds. The default is
L</SAMPLE_RATE>. If both L</seconds> and L</samples> are given, seconds will
be used.

=back

=head2 render_unpack

  my @samples = $tsf->render_unpack(%options);

Returns an array of of 16-bit sound samples using TinySoundFont. All of the
options are identical to L</render>.

=head2 db_to_vol

  my $volume = $tsf->db_to_vol(-10);

Convert from dB to a floating point volume. The dB is expressed as a number
between -100 and 0, and will map logarithmically to 0.0 to 1.0.

=head1 Terminology

The SoundFount terminology can get confusing at times, so I've included a quick
reference to help make sense of these.

=over

=item Terminology used directly in Audio::TinySoundFont

To be able to use Audio::TinySoundFont, you will need to know a couple simple
terms. They are likely easy to infer, but they are here so that their meaning
is explicit instead of implicit.

=over

=item SoundFont

Sometimes referred to as SoundFont2, this is a file format designed to store and
exchange synthesizer information. This includes the audio samples to create
the audio, how to generate and modify the samples to sound as expected, and
generally how to produce audio that the SoundFont creator wanted.

=item Preset

A Preset is the largest usable building block in a SoundFont and generally
represents a single instrument. If you've ever sat down to an electric keyboard
and selected "Electric Guitar", "Violin" or "Synth", you are selecting the
equivalent of a SoundFont preset.

=back

=item Terminology used when talking about SoundFonts

Reading the entire SoundFont2 specification can be daunting. In short, it is a
L<RIFF|https://en.wikipedia.org/wiki/Resource_Interchange_File_Format> file that
primarily holds 9 types of data, or "sub-chunks". All of this data ultimately
describes a Preset that is used in constructing audio by TinySoundFont. It is
not required to understand these to use Audio::TinySoundFont and will not be
used in the rest of the documentation.

=over

=item PHDR/PBAG (Preset)

These are the two sections that describe a Preset. A PHDR record describes a
Preset like the name, preset number and bank number. The PBAG contains what are
called Preset Zones which lists the generators and modulators to use for a
specific preset given a range of notes and velocity. One of those generators is
which Instrument to use, which has its own set of generators and modulators.

=item INST/IBAT (Instrument)

An instrument is very similar in structure to a Preset, but provides a layer
of indirection between the raw samples and the presets. A single Instrument
can be used in multiple Presets, for instance a single Guitar Instrument can be
used for a regular guitar as well one with extra reverb.
These two sections serve the same function as the Preset sections. A INST
describes an Instrument and the PBAG contains Instrument Zones which lists the
generators and modulators to use for a given range of notes and velocities. One
of the generators is the sample to use for this Instrument.

=item PGEN

=item PMOD

=item IGEN

=item IMOD

Each preset and instrument is composed of one or more generators and modulators.
The PGEN and PMOD sections are used to construct the Preset Zones, likewise the
IGEN and IMOD sections are used to construct Instrument Zones.
They describe a single aspect of how to construct the audio samples, for
instance adding a low-pass filter or reverb. Some are only available for a
preset, like what Instrument to use, and some are only available to Instruments
like what Sample to use.

Note: TinySoundFont does not currently process modulators.

=item SHDR (Samples)

This section describes the actual audio samples to be used, including a name,
the length, the original pitch, pitch correction, and looping configuration.
The actual audio samples are stored in a different RIFF chunk, but this
contains the references into that chunk about where to find the data.

=back

=back

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2020- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

L<Audio::TinySoundFont::Preset>, L<Audio::TinySoundFont::Builder>, L<TinySoundFont|https://github.com/schellingb/TinySoundFont>

=cut
