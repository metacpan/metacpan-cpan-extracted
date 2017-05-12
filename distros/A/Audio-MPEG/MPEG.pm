#
# $Id: MPEG.pm,v 1.6 2001/06/18 04:19:40 ptimof Exp $
#
# Copyright (c) 2001 Peter Timofejew. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#
# Audio::MPEG
#
# This name space is just used to load in the XS routines
#

package Audio::MPEG;

use strict;

require DynaLoader;

use vars qw($VERSION @ISA);

@ISA = qw(DynaLoader);

$VERSION = '0.04';

bootstrap Audio::MPEG $VERSION;

#
# Audio::MPEG::Decode
#

package Audio::MPEG::Decode;

use strict;
use Carp;

# only decode header (do not decode the frame data)
sub decode_frame_header {
	my $self = shift;
	return $self->decode_frame(1);
}

# returns undef for failure, 1 for success
sub verify_mp3file {
	my $self = shift;
	my $file = shift || croak("missing filename");
	my $full_verify = shift;		# 1 means decode as well
	my $num_errs = shift || 5;		# default to 5 errors maximum

	if (not open(IN, "<$file")) {
		carp("$file: $!");
		return undef;
	}
	my ($inbuf, $errs);
	while (my $read_bytes = read(IN, $inbuf, 40_000)) {
		$self->buffer($inbuf);
		if ($full_verify) {
			while ($self->decode_frame) {
				if (not $self->err_ok) {
					$errs++;
					return undef if $errs > $num_errs;
				}
			}
		} else {
			while ($self->decode_frame_header) {
				if (not $self->err_ok) {
					$errs++;
					return undef if $errs > $num_errs;
				}
			}
		}
		
	}
	close(IN);
	return 1;
}

1;
__END__

=head1 NAME

Audio::MPEG - Encoding and decoding of MPEG Audio (MP3)

=head1 SYNOPSIS

  use Audio::MPEG;

=head1 DESCRIPTION

B<Audio::MPEG> is a Perl interface to the B<LAME> and B<MAD> MPEG audio
Layers I, II, and III encoding and decoding libraries.

=head2 Rationale

I have been building a fairly extensive MP3 library, and decided to write
some software to help manage the collection. It's turned out to be a rather
cool piece of software (incidentally, I will be releasing it under the GPL
shortly), with both a web and command line interface, good searching,
integrated ripping, archive statistics, etc.

However, I also wanted to be able to stream audio, and verify the integrity
of files in the archive. It is certainly possible to stream audio (even
with re-encoding at a different bitrate) without resorting to writing 
interface glue like this module, but verification of the files was 
clumsy at best (e.g. scanning stdout/err for strings), and useless at worst.

Thus, B<Audio::MPEG> was born.

=head2 LAME

This is arguably the best quality MPEG encoder available (certainly the
best GPL encoder). Portions of the code have been optimized to take
advantage of some of the advanced features for Intel/AMD processors, but
even on non-optimized machines, such as the PowerPC, it performs quite well
(faster than real-time on late 90's (and later) machines).

=head2 MAD

This is a relatively new MPEG decoding library. I chose it after struggling
to clean up the MPEG decoding library included with LAME (which is based
on Michael Hipp's mpg123(1) implementation). In the end, I was very pleased
with the results. MAD performs it's decoding with an internal precision
of 24 bits (pro-level quality) with fixed-point arithmetic. The code
is very clean, and seems rock-solid. Although it may seem that it should
be faster than the mpg123(1) library due to the use of fixed-point arithmetic,
it is in fact about 60% or so of the speed (due to the higher resolution
audio). However, the ease of coding against B<MAD>, and the higher
precision of the output more than makes up for the slower decoding.

B<Audio::MPEG> can export the data at it's highest precision for programs
that wish to manipulate the data at the higher resolution.

=head2 Operating System Environment

I have only tested this on a Linux 2.4.x system so far, but I see no
reason why it should not work on any Un*x variant. In fact, it may actually
even work on a Windoze box (the underlying LAME and MAD libraries apparently
compile somehow on them). I am doing no special magic with the interface,
so presumably it will work under Windows. As you can probably tell, I
don't really care if it does (I'll may start caring if M$ releases
the source code to Windows under GPL, BSD, or Artistic licenses...). But,
for you poor, misguided souls that insist upon running Windows, I expect
that there should be little problem getting it to work.

=head2 Performance

You would think that with encoding/decoding audio, which is quite a
compute-intensive task, Perl would be much slower than the equivalent pure
C programs. Surprise... it is only about 3% slower (!) Even with the
mechanism I use here (Perl->C->Perl for B<every> frame, Perl 5.6.1 and
Linux 2.4.4 (PowerPC 7500) performs just fantastic. So, the moral of this
paragraph is to run your own performance tests, but there's no need to
think of your own Perl encoder/decoder will be inferior to a pure C/C++
implementation. The only drawback is that, depending upon how much
buffer space you use for reading, memory usage will be at least 3 times
as much (eh... RAM is cheap...)

=head1 INTERFACE

=head2 Audio::MPEG

This is simply the package that bootstraps the XS library, and there
is no external interface.

=head2 Audio::MPEG::Decode

=over 4

=item B<new>()

This creates a new object. Each object has it's own private context, so
it is possible to have more than one object created at a time.

Once a stream has started to be decoded, the object may only be used for
that stream (due to state information kept in the object).

=item B<$len> = B<buffer>(I<$data>)

This method adds an arbitrary "chunk" of input MP3 data to the internal
buffering pool. Typically, this is at least 4KB of data. A good length
of data to pass is 40KB (approximately 1 second of audio encoded at 320kbps
or 2.5 seconds of audio encoded at 128KBs).

Method returns the length of data, in bytes, that has not be decoded yet.

=item B<decode_frame>()

This method will process the next MP3 frame of the data that has been
buffered with B<buffer>(), prepares it for PCM synthesis. The prepared
data is stored in the object. Do not use both this function and
B<decode_frame_header>() on the same object.

Method returns 1 if a frame was decoded (successfully or not), and 0
if it ran out of data before finishing decoding.

Upon return, program should interrogate I<$obj->err>. If it is > 0, then
a decoding error has occurred, and no PCM synthesis is possible (i.e. frame
should be skipped). See the EXAMPLES section later in this document.

=item B<decode_frame_header>()

This method will process the next MP3 frame of the data that has been
buffered with B<buffer>(), and does B<not> prepare it for PCM synthesis.
The intent of this function is to verify the framing of the MP3 stream
for a rapid integrity check of the file. It is not a complete
check, as that is possible only with full decoding. However, simply
performing this framing check will catch the majority of errors found with
MP3 files. Do not use both this function and B<decode_frame>() on the same
object.

Method returns 1 if a frame was parsed (successfully or not), and 0
if it ran out of data before finishing parsing.

Upon return, program should interrogate I<$obj->err>. If it is > 0, then
a decoding error has occurred (i.e. frame
should be skipped). See the EXAMPLES section later in this document.

=item B<verify_mp3file>($I<filename> [, $I<full_verify>, $I<num_errs>])

This is a convenience function that will return 1 if the MP3 file
has less than 5 framing errors, or undef if there were more problems.

If the second parameter is 1, a full decoding of the MP3 file will
occur. If undef, it will only decode the frame headers and not the data
as well.

This may be further tuned by passing a third parameter that indicates the number
of errors to be found before declaring the verification a failure.

Method returns 1 if file is OK, undef if damaged.

=item B<synth_frame>()

This method will synthesize the PCM data for a single frame that was
prepared by B<decode_frame>(). The output PCM frame is stored in the object.

=item B<err>()

Returns the last error code, or 0 if no error. This, or err_ok(), should be
checked after every B<decode_frame>() or B<decode_frame_header>() call.

=item B<err_ok>()

Returns the 1 if the error is recoverable, or 0 if it's a bad error. This,
or err(), should be checked after every B<decode_frame>() or
B<decode_frame_header>() call.

=item B<errstr>()

Returns an English string describing the error condition.

=item B<current_frame>()

Returns the current MP3 frame that was decoded.

=item B<total_frames>()

Returns the total number of MP3 frames decoded. Used after decoding has
been completed.

=item B<frame_duration>()

Returns the length of the frame, in seconds, that was decoded.

=item B<total_duration>()

Returns the total duration, in seconds, that was decoded. Used after decoding
has been completed.

=item B<bit_rate>()

Returns the bitrate, in kbs, of the frame that was decoded.

=item B<average_bit_rate>()

Returns the average bitrate of the decoded frames. Used after decoding has
been completed.

=item B<sample_rate>()

Returns the samplerate, in Hertz, of the decoded frame.

=item B<layer>()

Returns the MPEG audio layer number of the decoded frame.

=item B<channels>()

Returns the number of PCM channels that were decoded (1 or 2) of the
decoded frame.

=item B<pcm>()

Returns the synthesized PCM structure of the decoded/synthesized frame.
This format is in a 24bit fixed-point format, and is only intended for
passing to an B<Audio::MPEG::Output> object. It is also intended to be
used by a planned future filtering object.

=back

=head2 Audio::MPEG::Output

=over 4

This creates a new object. Each object has it's own private context, so
it is possible to have more than one object created at a time.

The parameters for new are as follows:

=item B<new>(I<\%parameters>)

=over 4

=item I<out_sample_rate>

The target output samplerate (in Hertz). If this does not match the input
samplerate of the PCM samples, it will be resampled. Default is 44_100.

=item I<out_channels>

The number of output channels. If different from the input PCM samples,
it will be adjusted (mono->stereo or stereo->mono). Default is 2.

=item I<mode>

The algorithm used to decrease the precision of the input samples to match
the output precision. Valid values are 1 for simple rounding, and 2 for
dithering. Default is 2.

=item I<type>

The output stream format. Valid values are 1 (unsigned 8 bit PCM),
2 (signed 16 bit PCM), 3 (signed 24 bit PCM), 4 (signed 32 bit PCM),
5 (4 byte float PCM), 6 (8 bit Sun mulaw), and 7 (Microsoft WAV).

All PCM formats are in the B<native> (i.e. big or small endian) format
of the machine that generates the output. Default is 5.

=item I<apply_delay>

This will correct for the MP3 decoding delay. If set to 1, 1/2 of the first
frame's PCM stream will be skipped and not converted to an output stream.
Default is to not correct for delay.

=back

=item B<header>($I<datasize>)

This method will return a header (first few bytes of data) that is valid
for the output type. $I<datasize> refers to the length of audio data in bytes.
If not passed the length, B<header>() will output a valid header, except that
the embedded length will be zero. After the sample is decoded, header is
typically called again, and re-written to the beginning of the file (see
the EXAMPLE section of the document). If called with an object type that
does not have a header, this returns an empty scalar.

Currently, only Sun mulaw and WAV formats have headers.

=item B<encode>($I<pcm>)

This method will encode an input PCM stream and return a scalar containing
the output audio stream. Input is typically the output of
Audio::MPEG::Decode->pcm method.

=item B<clipped_samples>()

Returns the number of samples that had to be clipped to fit in the output
format.

=item B<peak_amplitude>()

Returns the amplitude, in decibels, of the highest sample.

=back

=head2 Audio::MPEG::Encode

=over 4

=item B<new>(I<\%parameters>)

This creates a new object. Each object has it's own private context, so
it is possible to have more than one object created at a time.

The parameters for new are as follows:

=over 4

=item I<in_sample_rate>

This is the input sample rate (in Hertz) and is used to in decoding the PCM
stream passed to the I<encode>() methods of this class. Allowed values are
8_000, 11_025, 12_000, 16_000, 22_050, 32_000, 44_100, and 48_000. If not
set, it will default to 44_100.

=item I<in_channels>

This is the number of input channels and is used by the I<encode>() methods
of this class in decoding the PCM stream. If not set, default is 2 channels
(stereo input).

=item I<out_sample_rate>

If set, the output sample rate (in Hertz) is (possibly) resampled to match this.
Allowed values are 8_000, 11_025, 12_000, 16_000, 22_050, 32_000, 44_100,
and 48_000. If not set, the LAME library will automatically select the best
output sample rate based on the other settings (such as compression ratio
or bitrate).

Note that this setting is B<independent> of the input sample frequency: LAME
will resample if required.

=item I<scale>

An amount that the output is scaled (multiplied) by. May be fractional.
Default is no scaling.

=item I<quality>

Encoding quality setting. Values range from 0 (best) to 9 (worst). Default
is 5.

=item I<mode>

The output channel mode. One of "stereo", "joint-stereo", or "mono". Default
is for LAME to switch based on the compression ratio and number of input
channels.

=item I<mode_automs>

Boolean to allow main/sideband switching threshold based on compression
ratio. Default is 0 (switching disabled).

=item I<free_format>

Boolean. Default is 0 (disabled).

=item I<compression_ratio>

Ratio of input/output compression. If neither I<compression_ratio> nor
I<bit_rate> are set, the output stream will be compressed by 11.025.
If both parameters are set, all time and space will implode.

=item I<bit_rate>

If supplied, output will be a constant bitrate. Mutually exclusive with
I<compression_ratio>.

=item I<copyright>

Marks output stream as being copyrighted. Default is 0.

=item I<original>

Marks output stream as original. Default is 1.

=item I<CRC>

If set to 1, CRCs are computed and inserted into the stream. Default is 0.
Note: many players have difficulty handling CRCs. It's not recommended
to set this flag to true (besides, it's of pretty limited value).

=item I<padding_type>

Frame padding. 0 is no padding, 1 is pad all frames, 2 is adjust padding
(default).

=item I<strict>

Enforce strict ISO compliance. Default is 0.

=item I<vbr>

Select variable bitrate output, and set type of VBR. Values are "vbr",
"old", "new", and "mtrh" (vbr and old are equivalent). Default is to not
encode VBR, but to used a constant bitrate.

=item I<vbr_quality>

Set the quality of VBR encoding. Values range from 0 (best) to 9 (worst).
LAME chooses default.

=item I<average_bitrate>

If set to a bitrate, VBR encoding is used so that the average bitrate
of the output MP3 stream equals this value.

=item I<min_bit_rate>

If set to a bitrate, the bitrate of the stream will not fall below this value
(unless the input stream is audio silence, then the stream may fall lower).

=item I<min_hard_bit_rate>

If set to a bitrate, the bitrate of the stream will never fall below this
value, even if the input stream is audio silence.

=item I<max_bit_rate>

If set to a bitrate, the bitrate of the stream will never exceed this rate.

=item I<lowpass_filter_frequency>

If set to a frequency (in Hertz), the input will pass through a filter
before being encoded. Values range from 1 to 50_000. Default is for LAME to
choose.

=item I<no_lowpass_filter>

If this exists, filtering is disabled.

=item I<lowpass_filter_width>

The width of the filter expressed as a percentage of the filter frequency.
Defaults to 15%.

=item I<highpass_filter_frequency>

If set to a frequency (in Hertz), the input will pass through a filter
before being encoded. Values range from 1 to 50_000. Default is for LAME to
choose. If set to -1, filtering is disabled.

=item I<no_highpass_filter>

If this exists, filtering is disabled.

=item I<highpass_filter_width>

The width of the filter expressed as a percentage of the filter frequency.
Defaults to 15%.

=item I<apply_delay>

This will correct for the MP3 encoding delay. If set to 1, the first
B<encoder_delay>() samples of the first frame's PCM stream will be
skipped and not encoded. Default is to not correct for delay.

=back

=item B<encoder_delay>()

This method will return the number of PCM samples that will be skipped on
the input due to the delay the encoder implicitly creates. By skipping these
samples, the output stream will have the same audio runtime as the input stream.

=item B<encode_float>(I<$pcm>)

This method will take the input PCM stream $I<pcm> and return zero or more
complete MP3 frames. The input is a series of multiplexed, B<native>
4-byte floats.  If there are two input channels, it will alternate between
left and right channels (starting with left). If it is a single channel,
it will be the left channel only.

Values of the samples may range from -1.0 to +1.0.

The output is a scalar that contains zero or more MP3 frames.

=item B<encode16>(I<$pcm>)

This method will take the input PCM stream $I<pcm> and return zero or more
complete MP3 frames. The input is a series of multiplexed, B<native>
signed 2-byte integers.  If there are two input channels, it will alternate
between left and right channels (starting with left). If it is a single
channel, it will be the left channel only.

Values of the samples may range from -32768 to +32767.

The output is a scalar that contains zero or more MP3 frames.

=item B<encode_flush>()

This method must always be used after the encoding is finished. It will
return zero or more MP3 frames.

=item B<encode_vbr_flush>(I<*FILE>)

This method may be called after B<encode_flush>() if a Xing VBR frame
is to be written to a file. Although not strictly required, if an MP3
stream was encoded as a VBR, the Xing frame contains information useful
to decoders, and is recommended to be used. If the MP3 stream is a constant
bitrate, calling this function performs no action. Also, if the output
stream is being emitted as a real-time stream, this function should not
be called, as it requires a file handle, and will perform a seek to to the
beginning of the file.

Important note: the file handle B<must> have been opened read/write (e.g.
open(FILE, "+>$filename"))

=back

=head1 EXAMPLES

Below are a few examples to show how to use this module.

=head2 MP3 to WAV

This will take an input MP3 file, and create an output WAV file that
is fixed to a sample rate of 44.1 kHz and 2 channels (it will resample
the input if needed). This would be is in creating WAV files for 
burning an audio CD (where it is necessary to have all input at
44.1 kHz, 2 channels).

 use Audio::MPEG;

 my $in_file = shift || "test.mp3";
 my $out_file = shift || "test.wav";

 open(IN, "<$in_file") || die "$in_file: $!";
 open(OUT, ">$out_file") || die "$out_file: $!";

 my $mp3 = Audio::MPEG::Decode->new;

 my ($in, $wav, $wav_len);

 while (my $read_bytes = read(IN, $in, 40_000)) {
     $mp3->buffer($in);

     while ($mp3->decode_frame) {
         if (not $mp3->err_ok) {
             printf("Frame: %u: %s\n", $mp3->current_frame,
                 $mp3->errstr);
             next;
         }

         $mp3->synth_frame;

         if (not $wav) {
             $wav = Audio::MPEG::Output->new({ type => 'wave' });
             print OUT $wav->header;
         }

         my $out = $wav->encode($mp3->pcm);
         $wav_len += length($out);
         print OUT $out;
     }
 }

 if (seek(OUT, 0, 0)) {
     print OUT $wav->header($wav_len);
 }

=head2 Reencode MP3

This will take an input MP3 file, and create an output MP3 file that
is a VBR encoded (128kbps average is default).

 use Audio::MPEG;

 my $in_file = shift || "test.mp3";
 my $out_file = shift || "test2.mp3";

 open(IN, "<$in_file") || die "$in_file: $!";

 # Important: OUT is opened r/w if it is a real file
 open(OUT, "+>$out_file") || die "$out_file: $!";

 my $mp3_in = Audio::MPEG::Decode->new;

 my ($in, $pcm);

 while (my $read_bytes = read(IN, $in, 40_000)) {
     $mp3_in->buffer($in);

     while ($mp3_in->decode_frame) {
         if (not $mp3_in->err_ok) {
             printf("Frame: %u: %s\n", $mp3_in->current_frame,
                 $mp3_in->errstr);
             next;
         }

         $mp3_in->synth_frame;

         if (not $pcm) {
             $pcm = Audio::MPEG::Output->new({
                 out_sample_rate => $mp3_in->sample_rate,
                 out_channels => $mp3_in->channels
             });
         }

         my $pcm_stream = $pcm->encode($mp3_in->pcm);

         if (not $mp3_out) {
             $mp3_out = Audio::MPEG::Encode->new({
                 vbr => "vbr",
                 in_sample_rate => $mp3_in->sample_rate,
                 in_channels => $mp3_in->channels
             });
         }

          print OUT $mp3_out->encode_float($pcm_stream);
     }
 }

 print OUT $mp3_out->encode_flush;
 $mp3_out->encode_vbr_flush(*OUT);

=head1 DATA TRANSFORMATIONS

If it is desired to perform audio processing on a PCM stream, it is a simple
matter of converting the output scalar from Audio::MPEG::Output to an array.
Processing can then be done on this array, and it can be transformed back
into an opaque scalar for input into Audio::MPEG::Encode (if the output
is to be encoded as an MP3).

Additionally, if the processing is to be accomplished by a C routine, all
that is required is for the C program to know the format of the scalar
(and the usual Perl XS SvPV() routine can be used to access the data).

=head2 Scalar to Array

The output of Audio::MPEG::Output is a (possibly) interleaved PCM stream.
What this means is that if the output is 2 channels, the first sample is the
left channel, the second is the right channel, the third the left channel, etc.
If the output is a single channel, all samples are the left channel.

The format is in the B<native> endian of the machine the program ran on (with
the exception of the WAVE format - this is always little-endian).

=over 4

=item I<pcm8>

This is an unsigned byte stream. 

my @a = unpack('C*', $out);

=item I<pcm16>

This is a signed 2 byte short stream, scaled by 15 bits.

@a = unpack('s*', $out);

=item I<pcm24, pcm32>

These are signed 4 byte longs (scaled by 23 and 31 bits respectively).

@a = unpack('l*', $out);

=item I<float>

This is a 4 byte floating point stream (range is -1.0 to +1.0).

@a = unpack('f*', $out);

=back

After unpacking, the next step is to demultiplex the interleaved array.
If the number of channels is 1, you are done (it is a mono signal). If
the number of channels is 2, then $a[0] is the first left channel sample,
$a[1] is the first right channel sample, $a[2] is the second left channel
sample, etc.

As for the range of values for each element, these are determined by the
byte size (except of course for I<float>). For example, I<pcm16> will 
be in the range of -32768 to +32767. Keep this in mind when coding your
analysis routines.

=head2 Array to Scalar

The input to Audio::MPEG::Encode is a (possibly) interleaved PCM stream.
If a Perl array contains data that you wish to encode into an MP3, it must
be transformed into an opaque scalar representing the (possibly) interleaved
PCM data. Please see the discussion above for details as to how the stream
is formatted and scaled.

=over 4

=item encode_float()

This method requires 4 byte floating point data.

$in = pack('f*', @a);

=item encode16()

This method requires 2 byte signed short data.

$in = pack('s*', @a);

=back

=head2 Example

Below is a simple example of reducing the volume of a sample by 2 (6 dB).
Please note that, for production use, any signal processing should be
written in C (and linked as an XS module) due to the much faster speed
of C over Perl for this type of processing (remember that a typical
song will contain millions of samples...)

 my @a = unpack('f*', $out);
 for (my $i = 0; $i < $#a; $i++) {
     $a[$i] /= 2.0;
 }
 $out = pack('f*', @a);

=head1 BUGS

=over 4

=item *

If B<very> small samples are used (less than 1/2 a second), and a very low
quality MP3 is generated (say, 8_000 Hz, mono), the first MP3 frame may
be white noise. The moral of the story is not to do this.

=item *

Although technically not a bug with this module, some MP3 players, such as
mp3blaster(1), do not deal well with low quality MP3s. If you use such a
player, and you suspect that the module did not create a valid MP3 file,
please try mpg123(1) or madplay(1) before submitting a bug report.

=back

=head1 TO DO

=over 4

=item *

Investigate and implement a better resampling algorithm for decoding.
Currently, a simple linear interpolation is done, which does the trick,
but a better sounding one should be possible.

=item *

Implement various filters (fade in/fade out, multi-band equalizer).
More serious filtering should be done with sox(1).

=item *

Implement an analysis module to compute information such as the average
power of the file (for normalizing volume levels in collections).

=item *

Add additional input data types (other than just native signed 16 bit PCM
and floating point) input to B<Audio::MPEG::Encode>.

=item *

Include more example programs (e.g. real-time re-encoding for use with
ICEcast, etc.)

=back

=head1 AUTHOR

Peter Timofejew E<lt>peter@timofejew.comE<gt>

=head1 CURRENT VERSION

The current version may always be found on CPAN, as well as at
http://timofejew.com/audiompeg/

=head1 REQUIRED LIBRARIES

The libraries required to build and use Audio::MPEG can also be found
at http://timofejew.com/audiompeg/

=over 4

=item B<LAME>

B<Audio::MPEG> was developed against version 3.88 (beta 1) of LAME, currently
maintained by Mark Taylor. This library can be found at
http://www.mp3dev.org/

=item B<MAD>

B<Audio::MPEG> was developed against version 0.13.0 (beta) of MAD, written
and maintained by Robert Leslie. This library can be found at
http://www.mars.org/home/rob/proj/mpeg/

=back

=head1 COPYRIGHT

Copyright (c) 2001 Peter Timofejew. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 SEE ALSO

lame(1),
madplay(1),
mpg123(1),
mp3blaster(1),
sox(1),
MP3::Info(3)

=cut
