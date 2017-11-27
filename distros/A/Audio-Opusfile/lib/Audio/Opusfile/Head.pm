package Audio::Opusfile::Head;
# Don't load this module directly, load Audio::Opusfile instead

use 5.014000;
use strict;
use warnings;

our $VERSION = '1.000';

1;
__END__

=encoding utf-8

=head1 NAME

Audio::Opusfile::Head - The header of an Ogg Opus file

=head1 SYNOPSIS

  use blib;
  use Audio::Opusfile;
  my $of = Audio::Opusfile->new_from_file('empty.opus');
  my $head = $of->head;
  say $head->version;           # 1
  say $head->channel_count;     # 2
  say $head->pre_skip;          # 356
  say $head->input_sample_rate; # 44100
  say $head->output_gain;       # 0
  say $head->mapping_family;    # 0
  say $head->stream_count;      # 1
  say $head->coupled_count;     # 1
  say $head->mapping(0);        # 0
  say $head->mapping(1);        # 1

=head1 DESCRIPTION

This module represents the header of an Ogg Opus file. See the
documentation of L<Audio::Opusfile> for more information.

=head1 METHODS

=over

=item $head->B<version>

The Ogg Opus format version, in the range 0...255.

The top 4 bits represent a "major" version, and the bottom four bits
represent backwards-compatible "minor" revisions.

The current specification describes version 1.

=item $head->B<channel_count>

The number of channels, in the range 1...255.

=item $head->B<pre_skip>

The number of samples that should be discarded from the beginning of
the stream.

=item $head->B<input_sample_rate>

The sampling rate of the original input.

All Opus audio is coded at 48 kHz, and should also be decoded at 48
kHz for playback (unless the target hardware does not support this
sampling rate). However, this field may be used to resample the audio
back to the original sampling rate, for example, when saving the
output to a file.

=item $head->B<output_gain>

The gain to apply to the decoded output, in dB, as a Q8 value in the
range -32768...32767.

The libopusfile API will automatically apply this gain to the decoded
output before returning it, scaling it by
pow(10,output_gain/(20.0*256)).

=item $head->B<mapping_family>

The channel mapping family, in the range 0...255.

Channel mapping family 0 covers mono or stereo in a single stream.
Channel mapping family 1 covers 1 to 8 channels in one or more
streams, using the Vorbis speaker assignments. Channel mapping family
255 covers 1 to 255 channels in one or more streams, but without any
defined speaker assignment.

=item $head->B<stream_count>

The number of Opus streams in each Ogg packet, in the range 1...255.

=item $head->B<coupled_count>

The number of coupled Opus streams in each Ogg packet, in the range
0...127.

This must satisfy 0 <= coupled_count <= stream_count and coupled_count
+ stream_count <= 255. The coupled streams appear first, before all
uncoupled streams, in an Ogg Opus packet.

=item $head->B<mapping>(I<$k>)

The mapping from coded stream channels to output channels.

Let C<< index = mapping[k] >> be the value for channel I<$k>. If
C<< index < 2 * coupled_count >>, then it refers to the left channel
from stream C<< (index/2) >> if even, and the right channel from
stream C<< (index/2) >> if odd. Otherwise, it refers to the output of
the uncoupled stream C<< (index-coupled_count) >>.

Dies if I<$k> is more than OPUS_CHANNEL_COUNT_MAX.

=back

=head1 SEE ALSO

L<Audio::Opusfile>,
L<http://opus-codec.org/>,
L<http://opus-codec.org/docs/opusfile_api-0.7/structOpusHead.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
