
# 3D Sounds streams for Audiere

package Audio::Audiere::Stream::3D;

# (C) by Tels <http://bloodgate.com/>

use strict;
require Exporter;

use vars qw/@ISA $VERSION/;
@ISA = qw/Audio::Audiere::Stream/;

$VERSION = '0.01';

use Audio::Audiere::Error;

##############################################################################
# alias names

BEGIN
  {
  *{_setVolume} = \&Audio::Audiere::Stream::_setVolume;
  }

##############################################################################
# constructors

sub new
  {
  # create a new 3D audio stream from an Audio::Audiere::Stream
  my ($class,$dev,$file,$buffering) = @_;

  my $self = bless { }, $class;

  my $rc = $self->_check_file($file);
  return $rc if $rc;                            # error? so return it!

  $self->{_dev} = $dev;
  $self->{_stream} =
    Audio::Audiere::Stream::_open($dev->_device(), $file, $buffering);

  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create stream from '$_[1]'.");
    }

  $self->{_vol} = 1;			# full volume	
  $self->{_muted} = 0;			# not muted
  $self->{_pitch} = 0;			# no shift
  $self->{_origin} = [0,0,0];		# center of sound origin
  $self->{_wobble} = [0,0,0];		# wobble center of sound origin?
  $self->{_damp} = 1;			# current dampening (1 = 0%, 0 = 100%)
  
  # for the current 3D representation
  $self->{_master} = $self->{_dev}->get3DMasterVolume(); # master 3D volume	
  $self->{_cur_vol} = $self->{_master};			 # full volume
  $self->{_cur_pan} = 0;				 # no pan
  $self->{_cur_pitch} = 0;				 # no pitch
  
  $self->{_id} = Audio::Audiere::Stream::ID();		# get a new ID
  
  if (!$self->{_stream})
    {
    return Audio::Audiere::Error->new(
      "Unknown error. Could not create 3D stream from $file.");
    }
  _setVolume($self->{_stream},$self->{_cur_vol}); # force master volume update
  $self;
  }

sub error
  {
  undef;
  }

sub DESTROY
  {
  my $self = shift;

  Audio::Audiere::Stream::_free_stream($self->{_stream}) if $self->{_stream};
  }

##############################################################################
# get methods

sub getPan
  {
  # pan is not supported on 3D streams, so return always 0 (no pan)
  my $self = shift;

  0;
  }

sub getDampeningFactor
  {
  my $self = shift;

  $self->{_damp};
  }

sub getOrigin
  {
  my $self = shift;

  @{$self->{_origin}};
  }

##############################################################################
# set methods

sub _set_master
  {
  my $self = shift;

  $self->{_master} = abs($_[0] || 0);
  }

sub setMuted
  {
  my $self = shift;

  $self->{_muted} = $_[0] ? 1 : 0;
  if ($self->{_muted})
    {
    # mute the stream
    _setVolume($self->{_stream},0);
    }
  else
    {
    # restore volume
    _setVolume($self->{_stream},$self->{_cur_vol});
    }
  }

sub setDampeningFactor
  {
  my $self = shift;

  $self->{_damp} = abs($_[0] || 0);
  }

sub setPan
  {
  my $self = shift;

  warn("Setting pan on 3D streams is not supported.");
  }

sub setVolume
  {
  my $self = shift;
  
  $self->{_vol} = abs($_[0] || 0);
  }

sub setPosition
  {
  my $self = shift;
  Audio::Audiere::Stream::_setPosition($self->{_stream},$_[0] || 0);
  }

sub setPitchShift
  {
  my $self = shift;

  $self->{_pitch} = $_[0] || 0;
  }

sub getPitchShift
  {
  my $self = shift;

  $self->{_pitch};
  }

sub setOrigin
  {
  my $self = shift;

  $self->{_origin} = [ $_[0], $_[1], $_[2] ];
  }

sub _update
  {
  # update _cur_vol, _cur_pan and _cur_pitch based on 3D calc
  my $self = shift;

  # _cur_vol = _master * _vol * _damp * dampening(distance) 
  $self->{_cur_vol} = $self->{_master} * $self->{_vol} * $self->{_damp};

  # XXX TODO: wobble origin for calculating the following values to get
  # sound sources that appear to come from a larger area

  # XXX TODO: calculate dampening depending on distance (and maybe on
  # angle between listener's view and stream source (100% in front, 80% in
  # direction of ears, 60% behind head?)

  # XXX TODO: calculate pan on rotation of listener and pos of stream origin

  # XXX TODO: calculate pitch depending on relative speeds
  
  # put the new values into effect
  Audio::Audiere::Stream::_setPan($self->{_stream},$self->{_cur_pan});
  Audio::Audiere::Stream::_setPan($self->{_stream},$self->{_cur_pitch});
  if (!$self->{_muted})
    {
    _setVolume($self->{_stream},$self->{_cur_vol});
    }
  }

1; # eof

__END__

=pod

=head1 NAME

Audio::Audiere::Stream::3D - a 3D sound (stream) in Audio::Audiere

=head1 SYNOPSIS

See Audio::Audiere for usage.

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This package provides you with individual sound streams. It should not be
used on it's own, but via Audio::Audiere.

=head2 Volume/Pan/Pitch calculation

The volume of a 3D sound source is influenced by the following factors:

=over 2

=item distance

The farther away a sound source is, the less loud it will appear.

=item dampening factor

A local dampening factor applied to each sound source can simulate sound
comming from behind windows, doors, columns etc.

=item master volume

The master volume might further reduce the volume.

=item volume

The volume of the sound source itself.

=back

The I<pan> of a 3D sound source is mainly influenced by the position of the
sound source in relation to the listener.

The I<pitch> is only modified for sound sources that move in relation to the
listener, thus simulating the I<Doppler> effect.

=head1 METHODS

Almost all of the methods from L<Audio::Audiere::Stream> can also be used
on a 3D stream, with a few exceptions and additions:

=head2 Not supported methods

The following methods are not suppored because they don't make sense on 3D
sounds:

=over 2

=item setPan, getPan

=back

=head2 Additional methods

The following additional methods are also available:

=over 2

=item setDampeningFactor

	$stream_3D->setDampeningFactor(1);

Sets a global dampening factor (1 => 0%, no dampening, 0 => 100%, completely
dampened). You can use this to modify the volume of a 3D sound source
temporarily without having to store and modify their general volume.

For instance, a sound source that is not in line of sight of the listener
could be dampened by 20%, another one behind a window by 60% and so on.

Set whether the stream is I<visible> from the listener or not. The idea
behind this is that sound sources not directly visible get damped by a certain
factor. For instance, a sound source behind a stone column would be not as
loud as one directly visible.

=item getDampeningFactor

	if ($stream_3D->getVisible()) { ... }

Returns the dampening factor for this stream. See L<setDampeningFactor>.

=item setOrigin

	$stream_3d->setOrigin( $x, $y, $z );

Sets the center point of the 3D sound source, e.g. where the sound will
appear to come from.

=item getOrigin

	($x,$y,$z) = $stream_3d->getOrigin();

Returns the center point of the 3D sound source, e.g. where the sound will
appear to come from.

=back

=head1 BUGS

The 3D sound support is not yet fully working.

=head1 AUTHORS

(c) 2004 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Audio::Audiere>, L<http://audiere.sf.net/>.

=cut

