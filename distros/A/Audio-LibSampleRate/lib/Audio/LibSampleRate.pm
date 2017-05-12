package Audio::LibSampleRate;

use 5.008009;
use strict;
use warnings;
use parent qw/Exporter/;

my @constants;
BEGIN { @constants = qw/SRC_SINC_BEST_QUALITY SRC_SINC_MEDIUM_QUALITY SRC_SINC_FASTEST SRC_ZERO_ORDER_HOLD SRC_LINEAR/ }
use constant +{ map { $constants[$_] => $_ } 0 .. $#constants };

our @EXPORT_OK = (qw/src_simple src_get_name src_get_description/, @constants);
our @EXPORT = @EXPORT_OK;

our $VERSION = '0.002001';

use XSLoader;
XSLoader::load('Audio::LibSampleRate', $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Audio::LibSampleRate - interface to Secret Rabbit Code audio sample rate converter

=head1 SYNOPSIS

  use Audio::LibSampleRate;
  use 5.010;

  my @in = (1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6);
  my @out;

  # High quality sample rate doubling
  say join ' ', map { sprintf "%.1f", $_ } src_simple \@in, 2;
  # 1.1 1.1 1.7 1.7 1.9 1.9 2.2 2.2 ...

  # Very low quality sample rate halving
  say join ' ', src_simple [1 .. 10], 1/2, SRC_LINEAR, 1;
  # 1 2 4 6 8

  # Halve first half, Double second half. Smooth transition.
  my $src = Audio::LibSampleRate->new(SRC_ZERO_ORDER_HOLD, 1);
  say join ' ', $src->process([1 ..  5], 1/2);  # 1 2 4
  say join ' ', $src->process([6 .. 10], 2, 1); # 6 8 9
  # (the doubling doesn't happen due to the smooth transition)

  # Halve first half, Double second half. Step transition.
  $src->reset;
  say join ' ', $src->process([1 ..  5], 1/2);  # 1 2 4
  $src->set_ratio(2);
  say join ' ', $src->process([6 .. 10], 2, 1); # 6 6 7 7 8 8 9 9 10

  say src_get_name SRC_SINC_FASTEST; # Fastest sinc interpolator
  say src_get_description SRC_SINC_FASTEST;
  # Band limited sinc interpolation, fastest, 97dB SNR, 80% BW.

=head1 DESCRIPTION

Secret Rabbit Code (aka libsamplerate) is a Sample Rate Converter for
audio. One example of where such a thing would be useful is converting
audio from the CD sample rate of 44.1kHz to the 48kHz sample rate used
by DAT players.

SRC is capable of arbitrary and time varying conversions ; from
downsampling by a factor of 256 to upsampling by the same factor.
Arbitrary in this case means that the ratio of input and output sample
rates can be an irrational number. The conversion ratio can also vary
with time for speeding up and slowing down effects.

SRC provides a small set of converters to allow quality to be traded
off against computation cost. The current best converter provides a
signal-to-noise ratio of 145dB with -3dB passband extending from DC to
96% of the theoretical best bandwidth for a given pair of input and
output sample rates.

There are two interfaces: a simple procedural interface which converts
a single block of samples in one go, and a more complex object
oriented interface which can handle streaming data, for situations
where the data is received in small pieces.

The underlying library also defines a callback interface, which is not
yet implemented in Audio::LibSampleRate.

All functions and methods below die in case of error with a message
containing the error number and description, as returned by SRC.

=head2 The simple interface

This interface consists of a single function, exported by default:

B<src_simple>(\I<@interleaved_frames>, I<$ratio>, I<$converter_type>, I<$channels>)

where I<@interleaved_frames> is an array of frames in interleaved
format, I<$ratio> is the conversion ratio
(C<output_sample_rate/input_sample_rate>), I<$converter_type> is the
converter as described in the L</"Converter types"> section, and
I<$channels> is the number of channels.

If not supplied, the I<$converter_type> defaults to the best available
converter and I<$channels> defaults to 2 (stereo sound).

The function returns a list of samples, the result of the conversion.

=head2 The object oriented interface

The following methods are available:

=over 4

=item Audio::LibSampleRate->B<new>(I<$converter_type>, I<$channels>)

Creates a new Audio::LibSampleRate object. I<$converter_type> and
I<$channels> have the same meaning and default values as in the
previous section.

=item $self->B<process>(\I<@interleaved_frames>, I<$ratio>, I<$end_of_input>)

The most important function. I<@interleaved_frames> is an array of
frames to be processed in interleaved format, I<$ratio> is the
conversion ratio, and I<$end_of_input> is a boolean (defaulting to
false) that should be true if this is the last piece of data, false
otherwise.

The function returns a list of samples, the result of the conversion.

=item $self->B<reset>

This function resets the internal state of the Audio::LibSampleRate
object. It should be called when the sample rate converter is used on
two separate, unrelated blocks of audio.

=item $self->B<set_ratio>($new_ratio)

Normally, when updating the I<$ratio> argument in B<process> the
library tries to smoothly transition between the previous and the
current conversion ratios. This function changes the ratio without a
smooth transition, achieving a step respone in the conversion ratio.

=back

=head2 Converter types

SRC currently offers 5 converters, numbered from 0 to 4. This module
includes constants for the available converters, all of them exported
by default.

=over 4

=item SRC_SINC_BEST_QUALITY

This is a bandlimited interpolator derived from the mathematical sinc
function and this is the highest quality sinc based converter,
providing a worst case Signal-to-Noise Ratio (SNR) of 97 decibels (dB)
at a bandwidth of 97%.

This is the default converter for B<src_simple> and B<new>.

=item SRC_SINC_MEDIUM_QUALITY

This is another bandlimited interpolator much like the previous one.
It has an SNR of 97dB and a bandwidth of 90%. The speed of the
conversion is much faster than the previous one.

=item SRC_SINC_FASTEST

This is the fastest bandlimited interpolator and has an SNR of 97dB
and a bandwidth of 80%.

=item SRC_ZERO_ORDER_HOLD

A Zero Order Hold converter (interpolated value is equal to the last
value). The quality is poor but the conversion speed is blindlingly
fast.

=item SRC_LINEAR

A linear converter. Again the quality is poor, but the conversion
speed is blindingly fast.

=back

The library also includes two functions that provide human-readable
information about converters. Both are exported by default.

=over

=item B<src_get_name>(I<$converter_type>)

Given a converter, returns its human-readable name.

=item B<src_get_description>(I<$converter_type>)

Given a converter, returns its human-readable description.

=back

=head1 SEE ALSO

L<http://www.mega-nerd.com/SRC/api.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
