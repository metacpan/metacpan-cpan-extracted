package Audio::FLAC::Decoder;

use strict;
use vars qw($VERSION);

$VERSION = '0.3';

BOOT_XS: {
        # If I inherit DynaLoader then I inherit AutoLoader
	require DynaLoader;

	# DynaLoader calls dl_load_flags as a static method.
	*dl_load_flags = DynaLoader->can('dl_load_flags');

	do {__PACKAGE__->can('bootstrap') ||
		\&DynaLoader::bootstrap}->(__PACKAGE__,$VERSION);
}

1;

__END__

=head1 NAME

Audio::FLAC::Decoder - An object-oriented FLAC decoder

=head1 SYNOPSIS

  use Audio::FLAC::Decoder;
  my $decoder = Audio::FLAC::Decoder->open("song.flac");
  my $buffer;
  while ((my $len = $decoder->sysread($buffer) > 0) {
    # do something with the PCM stream
  }

  OR

  open FLAC, "song.flac" or die $!;
  my $decoder = Audio::FLAC::Decoder->open(\*FLAC);

  OR

  # can also be IO::Socket or any other IO::Handle subclass.
  my $fh = IO::Handle->new("song.flac");
  my $decoder = Audio::FLAC::Decoder->open($fh);

=head1 DESCRIPTION

This module provides users with Decoder objects for FLAC files.
One can read data in PCM format from the stream, seek by pcm samples, or time.

=head1 CONSTRUCTOR

=head2 C<open ($filename)>

Opens an FLAC file for decoding. It opens a handle to the file or uses
an existing handle and initializes all of the internal FLAC decoding
structures.  Note that the object will maintain open file descriptors until
the object is collected by the garbage handler. Returns C<undef> on failure.

=head1 INSTANCE METHODS

=head2 C<sysread ($buffer, [$size])>

Reads PCM data from the FLAC stream into C<$buffer>.  Returns the
number of bytes read, 0 when it reaches the end of the stream, or a
value less than 0 on error.  The optional size can specify how many bytes to read.

=head2 C<raw_seek ($pos)>

Seeks through the compressed bitstream to the offset specified by
C<$pos> in raw bytes.  Returns 0 on success.

=head2 C<sample_seek ($pos)>

Seeks through the bitstream to the offset specified by C<$pos> in pcm
samples. Returns 0 on success.

=head2 C<time_seek ($pos, [$page])>

Seeks through the bitstream to the offset specified by C<$pos> in
seconds. Returns 0 on success.

=head2 C<bitrate ([$stream])>

Returns the average bitrate for the specified logical bitstream.  If
C<$stream> is left out or set to -1, the average bitrate for the entire
stream will be reported.

=head2 C<time_total ([$stream])>

Returns the total number of seconds in the bitstream.

=head2 C<raw_tell ()>

Returns the current offset in bytes.

=head2 C<time_tell ()>

Returns the current offset in seconds. - NOT YET IMPLEMENTED

=head1 REQUIRES

libFLAC

=head1 COPYRIGHT

Copyright (c) 2004-2008, Dan Sully.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

=head1 SEE ALSO

L<Audio::FLAC::Header>

=cut
