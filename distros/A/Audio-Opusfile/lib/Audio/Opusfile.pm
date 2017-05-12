package Audio::Opusfile;

use 5.014000;
use strict;
use warnings;
use Carp;

use parent qw/Exporter/;
use AutoLoader;

my @constants =
  qw/OPUS_CHANNEL_COUNT_MAX
	 OP_ABSOLUTE_GAIN
	 OP_DEC_FORMAT_FLOAT
	 OP_DEC_FORMAT_SHORT
	 OP_DEC_USE_DEFAULT
	 OP_EBADHEADER
	 OP_EBADLINK
	 OP_EBADPACKET
	 OP_EBADTIMESTAMP
	 OP_EFAULT
	 OP_EIMPL
	 OP_EINVAL
	 OP_ENOSEEK
	 OP_ENOTAUDIO
	 OP_ENOTFORMAT
	 OP_EOF
	 OP_EREAD
	 OP_EVERSION
	 OP_FALSE
	 OP_GET_SERVER_INFO_REQUEST
	 OP_HEADER_GAIN
	 OP_HOLE
	 OP_HTTP_PROXY_HOST_REQUEST
	 OP_HTTP_PROXY_PASS_REQUEST
	 OP_HTTP_PROXY_PORT_REQUEST
	 OP_HTTP_PROXY_USER_REQUEST
	 OP_PIC_FORMAT_GIF
	 OP_PIC_FORMAT_JPEG
	 OP_PIC_FORMAT_PNG
	 OP_PIC_FORMAT_UNKNOWN
	 OP_PIC_FORMAT_URL
	 OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST
	 OP_TRACK_GAIN/;

our @EXPORT_OK = @constants;
our @EXPORT = @constants;

our $VERSION = '0.005001';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Audio::Opusfile::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Audio::Opusfile', $VERSION);
require Audio::Opusfile::Head;
require Audio::Opusfile::Tags;
require Audio::Opusfile::PictureTag;

# Preloaded methods go here.

sub new_from_file {
	my ($class, $file) = @_;
	open_file($file)
}

sub new_from_memory {
	my ($class, $buf) = @_;
	open_memory($buf)
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::Opusfile - partial interface to the libopusfile Ogg Opus library

=head1 SYNOPSIS

  use Audio::Opusfile;
  my $of = Audio::Opusfile->new_from_file('silence.opus');
  my $tags = $of->tags;
  say $tags->query('TITLE'); # Cellule

=head1 DESCRIPTION

Opus is a totally open, royalty-free, highly versatile audio codec.
Opus is unmatched for interactive speech and music transmission over
the Internet, but is also intended for storage and streaming
applications. It is standardized by the Internet Engineering Task
Force (IETF) as RFC 6716 which incorporated technology from Skype's
SILK codec and Xiph.Org's CELT codec.

libopusfile is a library for decoding and basic manipulation of Ogg
Opus files.

Audio::Opusfile is an interface to libopusfile. It exports nearly all
of the functions for obtaining metadata of an Opus file or buffer in
that library. Future versions will additionally provide functions for
decoding Opus data into PCM.

The API might change in future versions.

=head1 METHODS

=over

=item Audio::Opusfile->B<new_from_file>(I<$file>)

Creates a new Audio::Opusfile object from an Ogg Opus file.

Dies if the given file does not exist or is not a valid Ogg Opus file.

=item Audio::Opusfile->B<new_from_memory>(I<$buffer>)

Creates a new Audio::Opusfile object from a buffer containing Ogg Opus
data.

Dies if the given buffer does not contain valid data.

=item Audio::Opusfile::test(I<$buffer>)

Returns true if the given buffer looks like the beginning of a valid
Ogg Opus file, false otherwise.

Dies if the given buffer does not have sufficient data to tell if it
is an Opus stream or if it looks like a Opus stream but parsing it
failed.

=item $of->B<head>

Returns an L<Audio::Opusfile::Head> object corresponding to the file.

=item $of->B<tags>

Returns an L<Audio::Opusfile::Tags> object corresponding to the file.

=item $of->B<seekable>

Returns whether or not the data source being read is seekable.

=item $of->B<link_count>

Returns the number of links in this chained stream. Always returns 1
for unseekable sources.

=item $of->B<serialno>([I<$link_index>])

Get the serial number of the given link in a (possibly-chained) Ogg
Opus stream. If the given index is greater than the total number of
links, this returns the serial number of the last link.

If the source is not seekable, I<$link_index> is negative, or
I<$link_index> is not given, then this function returns the serial
number of the current link.

=item $of->B<raw_total>([I<$link_index>])

Get the total (compressed) size of the stream (with no arguments), or
of an individual link in a (possibly-chained) Ogg Opus stream (with
one nonnegative argument), including all headers and Ogg muxing
overhead.

The stream must be seekable to get the total. A negative value is
returned if the stream is not seekable.

B<Warning:> If the Opus stream (or link) is concurrently multiplexed
with other logical streams (e.g., video), this returns the size of the
entire stream (or link), not just the number of bytes in the first
logical Opus stream. Returning the latter would require scanning the
entire file.

=item $of->B<pcm_total>([I<$link_index>])

Get the total PCM length (number of samples at 48 kHz) of the stream
(with no arguments), or of an individual link in a (possibly-chained)
Ogg Opus stream (with one nonnegative argument).

Users looking for op_time_total() should use this function instead.
Because timestamps in Opus are fixed at 48 kHz, there is no need for a
separate function to convert this to seconds.

The stream must be seekable to get the total. A negative value is
returned if the stream is not seekable.

=item $of->B<current_link>

Retrieve the index of the current link.

This is the link that produced the data most recently read by
op_read_float() or its associated functions, or, after a seek, the
link that the seek target landed in. Reading more data may advance the
link index (even on the first read after a seek).

=item $of->B<bitrate>([I<$link_index>])

Computes the bitrate of the stream (with no arguments), or of an
individual link in a (possibly-chained) Ogg Opus stream (with one
nonnegative argument).

The stream must be seekable to compute the bitrate. A negative value
is returned if the stream is not seekable.

B<Warning:> If the Opus stream (or link) is concurrently multiplexed with
other logical streams (e.g., video), this uses the size of the entire
stream (or link) to compute the bitrate, not just the number of bytes
in the first logical Opus stream.

=item $of->B<bitrate_instant>

Compute the instantaneous bitrate, measured as the ratio of bits to
playable samples decoded since a) the last call to B<bitrate_instant>,
b) the last seek, or c) the start of playback, whichever was most
recent.

This will spike somewhat after a seek or at the start/end of a chain
boundary, as pre-skip, pre-roll, and end-trimming causes samples to be
decoded but not played.

=item $of->B<raw_tell>

Obtain the current value of the position indicator of I<$of>. This is
the byte position that is currently being read from.

=item $of->B<pcm_tell>

Obtain the PCM offset of the next sample to be read.

If the stream is not properly timestamped, this might not increment by
the proper amount between reads, or even return monotonically
increasing values.

=item $of->B<raw_seek>(I<$offset>)

Seek to a byte offset relative to the compressed data.

This also scans packets to update the PCM cursor. It will cross a
logical bitstream boundary, but only if it can't get any packets out
of the tail of the link to which it seeks.

=item $of->B<pcm_seek>(I<$offset>)

Seek to the specified PCM offset, such that decoding will begin at
exactly the requested position. The PCM offset is in samples at 48 kHz
relative to the start of the stream.

=item $of->B<set_gain_offset>(I<$gain_type>, I<$gain_offset>)

Sets the gain to be used for decoded output.

By default, the gain in the header is applied with no additional
offset. The total gain (including header gain and/or track gain, if
applicable, and this offset), will be clamped to [-32768,32767]/256
dB. This is more than enough to saturate or underflow 16-bit PCM.

B<Note:> The new gain will not be applied to any already buffered,
decoded output. This means you cannot change it sample-by-sample, as
at best it will be updated packet-by-packet. It is meant for setting a
target volume level, rather than applying smooth fades, etc.

I<$gain_type> is one of OP_HEADER_GAIN, OP_TRACK_GAIN, or
OP_ABSOLUTE_GAIN. I<$gain_offset> is in 1/256ths of a dB.

=item $of->B<set_dither_enabled>(I<$enabled>)

Sets whether or not dithering is enabled for 16-bit decoding.

By default, when libopusfile is compiled to use floating-point
internally, calling read() or read_stereo() will first decode to
float, and then convert to fixed-point using noise-shaping dithering.
This flag can be used to disable that dithering. When the application
uses read_float() or read_float_stereo(), or when the library has been
compiled to decode directly to fixed point, this flag has no effect.

=item $of->B<read>([I<$bufsize>])

It is recommended to use B<read_float> instead of this method if the
rest of your audio processing chain can handle floating point.

Reads more samples from the stream. I<$bufsize> is the maximum number
of samples read, and it defaults to 1048576. Returns a list whose
first element is the link index this data was decoded from, and the
rest of the elements are PCM samples, as signed 16-bit values at 48
kHz with a nominal range of [-32768,32767). Multiple channels are
interleaved using the L<Vorbis channel ordering|https://www.xiph.org/vorbis/doc/Vorbis_I_spec.html#x1-810004.3.9>.

You can use C<< $of->head($li)->channel_count >> to find out the
channel count of a given link index.

=item $of->B<read_float>([I<$bufsize>])

Like B<read>, but samples are signed floats with a nominal range of
[-1.0, 1.0].

=item $of->B<read_stereo>([I<$bufsize>])

Like B<read>, but downmixes the stream to stereo (therefore you will
always get two channels) and does NOT return the link index (the first
return value is the first sample).

=item $of->B<read_float_stereo>([I<$bufsize>])

Like B<read_float>, but downmixes the stream to stereo (therefore you
will always get two channels) and does NOT return the link index (the
first return value is the first sample).

=back

=head1 EXPORT

All constants are exported by default:

  OPUS_CHANNEL_COUNT_MAX
  OP_ABSOLUTE_GAIN
  OP_DEC_FORMAT_FLOAT
  OP_DEC_FORMAT_SHORT
  OP_DEC_USE_DEFAULT
  OP_EBADHEADER
  OP_EBADLINK
  OP_EBADPACKET
  OP_EBADTIMESTAMP
  OP_EFAULT
  OP_EIMPL
  OP_EINVAL
  OP_ENOSEEK
  OP_ENOTAUDIO
  OP_ENOTFORMAT
  OP_EOF
  OP_EREAD
  OP_EVERSION
  OP_FALSE
  OP_GET_SERVER_INFO_REQUEST
  OP_HEADER_GAIN
  OP_HOLE
  OP_HTTP_PROXY_HOST_REQUEST
  OP_HTTP_PROXY_PASS_REQUEST
  OP_HTTP_PROXY_PORT_REQUEST
  OP_HTTP_PROXY_USER_REQUEST
  OP_PIC_FORMAT_GIF
  OP_PIC_FORMAT_JPEG
  OP_PIC_FORMAT_PNG
  OP_PIC_FORMAT_UNKNOWN
  OP_PIC_FORMAT_URL
  OP_SSL_SKIP_CERTIFICATE_CHECK_REQUEST
  OP_TRACK_GAIN


=head1 SEE ALSO

L<Audio::Opusfile::Head>,
L<Audio::Opusfile::Tags>,
L<http://opus-codec.org/>,
L<http://opus-codec.org/docs/opusfile_api-0.7/index.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
