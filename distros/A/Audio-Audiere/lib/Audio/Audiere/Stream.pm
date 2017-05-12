
# Soundstreams for Audiere

package Audio::Audiere::Stream;

# (C) by Tels <http://bloodgate.com/>

use strict;
require Exporter;

use vars qw/@ISA $VERSION/;
@ISA = qw/Exporter/;

$VERSION = '0.02';

use Audio::Audiere::Error;

##############################################################################
# protected vars

# each 3D sound stream will get a unique ID
  {
  my $id = 1;
  sub ID { return $id++;}
  }

##############################################################################
# constructors

sub _check_file
  {
  my ($self, $file) = @_;

  if (!-e $file)
    {
    return Audio::Audiere::Error->new(
      "Could not create stream from '$_[1]': No such file.");
    }

  if (!-f $file)
    {
    return Audio::Audiere::Error->new(
      "Could not create stream from '$_[1]': Not a file.");
    }

  undef;					# okay
  }

sub new
  {
  # create a new audio stream from file or memory
  my $class = shift;
  my ($dev, $file, $buffering) = @_;

  my $self = bless { }, $class;

  my $rc = $self->_check_file($file);
  return $rc if $rc;				# error? so return it!

  $self->{_dev} = $dev;
  $self->{_stream} = _open($dev->_device(), $file, $buffering);
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream from '$_[1]'.");
    }
  
  $self->{_id} = ID();			# get a new ID
 
  $self->{_muted} = 0;			# unmuted
  $self->{_vol} = 1;
  $self->{_master} = $dev->getMasterVolume();
  $self->setVolume($self->{_vol});	# force master volume update
  
  $self;
  }

sub tone
  {
  # create a new audio stream of a tone with a certain frequenzy
  my $class = shift;
  my ($dev,$freq) = @_;

  my $self = bless { }, $class;

  $self->{_dev} = $dev;
  $self->{_stream} = _tone($dev->_device(),$freq);
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream with tone of frequenzy '$_[0]'.");
    }
  $self->{_id} = ID();			# get a new ID
 
  $self->{_muted} = 0;			# unmuted
  $self->{_vol} = 1;
  $self->{_master} = $dev->getMasterVolume();
  $self->setVolume($self->{_vol});	# force master volume update
  $self;
  }

sub square_wave
  {
  # create a new audio stream of a square_wave tone with a certain frequenzy
  my $class = shift;
  my ($dev,$freq) = @_;

  my $self = bless { }, $class;

  $self->{_dev} = $dev;
  $self->{_stream} = _square_wave($dev->_device(),$freq);
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream with square wave with frequenzy '$_[0]'.");
    }
  $self->{_id} = ID();			# get a new ID
 
  $self->{_muted} = 0;			# unmuted
  $self->{_vol} = 1;
  $self->{_master} = $dev->getMasterVolume();
  $self->setVolume($self->{_vol});	# force master volume update
  $self;
  }

sub white_noise
  {
  # create a new audio stream playing white noise
  my ($class,$dev) = @_;

  my $self = bless { }, $class;

  $self->{_dev} = $dev;
  $self->{_stream} = _white_noise($dev->_device());
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream with white noise.");
    }
  $self->{_muted} = 0;			# unmuted
  $self->{_id} = ID();			# get a new ID
 
  $self->{_vol} = 1;
  $self->{_master} = $dev->getMasterVolume();
  $self->setVolume($self->{_vol});	# force master volume update
  $self;
  }

sub pink_noise
  {
  # create a new audio stream playing pink noise (which is noise with an
  # equal power distribution among octaves (logarithmic), not frequencies.
  my ($class,$dev) = @_;

  my $self = bless { }, $class;

  $self->{_dev} = $dev;
  $self->{_stream} = _pink_noise($dev->_device());
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream with pink noise.");
    }
  $self->{_id} = ID();			# get a new ID
  $self->{_muted} = 0;			# unmuted
  $self->{_vol} = 1;
  $self->{_master} = $dev->getMasterVolume();
  $self->setVolume($self->{_stream},$self->{_vol}); # force master vol update
  $self;
  }

sub _set_master
  {
  my $self = shift;

  $self->{_master} = abs($_[0] || 0);
  if (!$self->{_muted})
    {
    _setVolume($self->{_stream},$self->{_vol} * $self->{_master});
    }
  }

sub error
  {
  undef;
  }

sub DESTROY
  {
  my $self = shift;

  _free_stream($self->{_stream}) if $self->{_stream};
  }

sub play
  {
  my $self = shift;
  _play($self->{_stream});
  }

sub stop
  {
  my $self = shift;
  _stop($self->{_stream});
  }

##############################################################################
# get methods

sub getPan
  {
  my $self = shift;
  _getPan($self->{_stream});
  }

sub getRepeat
  {
  my $self = shift;
  _getRepeat($self->{_stream});
  }

sub getVolume
  {
  my $self = shift;

  $self->{_vol};
  }

sub setMuted
  {
  my $self = shift;

  $self->{_muted} = $_[0] ? 1 : 0;
  if ($self->{_muted})
    {
    _setVolume($self->{_stream},0);			# mute the stream
    }
  else
    {
    # restore volume
    _setVolume($self->{_stream},$self->{_vol} * $self->{_master});
    }
  }

sub getPosition
  {
  my $self = shift;
  _getPosition($self->{_stream});
  }

sub getPitchShift
  {
  my $self = shift;
  _getPitch($self->{_stream});
  }

sub getLength
  {
  my $self = shift;
  _getLength($self->{_stream});
  }

##############################################################################
# is... methods

sub isPlaying
  {
  my $self = shift;
  _isPlaying($self->{_stream});
  }

sub isSeekable
  {
  my $self = shift;
  _isSeekable($self->{_stream});
  }

sub isMuted
  {
  my $self = shift;
  $self->{_muted};
  }

##############################################################################
# set methods

sub setPan
  {
  my $self = shift;
  _setPan($self->{_stream},$_[0] || 0);
  }

sub setRepeat
  {
  my $self = shift;
  _setRepeat($self->{_stream},$_[0] ? 1 : 0);
  }

sub setVolume
  {
  my $self = shift;

  $self->{_vol} = abs($_[0] || 0);
  $self->{_vol} = 1 if $self->{_vol} > 1;

  if (!$self->{_muted})
    {
    _setVolume($self->{_stream},$self->{_vol} * $self->{_master});
    }
  $self->{_vol};
  }

sub setPosition
  {
  my $self = shift;
  _setPosition($self->{_stream},$_[0] || 0);
  }

sub setPitchShift
  {
  my $self = shift;
  _setPitch($self->{_stream},$_[0] || 0);
  }

sub id
  {
  my $self = shift;

  $self->{_id};
  }

1; # eof

__END__

=pod

=head1 NAME

Audio::Audiere::Stream - a sound (stream) in Audio::Audiere

=head1 SYNOPSIS

See Audio::Audiere for usage.

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This package provides you with individual sound streams. It should not be
used on it's own, but via Audio::Audiere.

=head1 METHODS

=over 2

=item error

        if ($stream->error())
          {
          print "Fatal error: ", $stream->error(),"\n";
          }

Return the last error message, or undef for no error.

=item play

Start playing the stream.

=item stop

Stop playing the stream.

=item getLength

=item isSeekable

	$stream->setPosition(100) if $stream->isSeekable();

Returns whether the stream is seekable or not. 

=item isMuted
	
	if ($stream->isMuted())
	  {
	  ...
	  }

Returns true if the stream is currently muted.

=item isPlaying

        while ($stream->isPlaying())
          {
          ...
          }

Returns true if the stream is still playing.

=item getPosition

Returns the current position in the stream.

=item setPosition

Set the current position in the stream.

=item getFormat

=item getSamples

=item getVolume

Returns the volume of the stream as a value between 0 and 1.

=item setVolume

Set the volume of the stream as a value between 0 and 1.

=item getRepeat

Returns true if the stream is repeating (aka looping).

=item setRepeat

        $stream->setRepeat(1);          # loop
        $stream->setRepeat(0);          # don't loop

If true, the stream will repeat (aka loop).

=item setPan

        $stream->setPan ( -1.0 );       # -1.0 = left, 0 = center, 1.0 = right

Set the panning of the sound from -1.0 to +1.0.

=item getPan

Returns the current panning of the sound from -1.0 to +1.0. See L<setPan>.

=item setMuted

	$stream->setMuted (1);		# mute the stream
	...	
	$stream->setMuted (0);		# unmute the stream again

Sets the stream to muted or unmuted. The stream will continue to play
inaudible and also remembers it's volume, which will be restored on unmute.

=back

=head1 AUTHORS

(c) 2004 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Audio::Audiere>, L<Audio::Audiere::Stream>, L<Audio::Audiere::Stream::3D>,
L<http://audiere.sf.net/>.

=cut

