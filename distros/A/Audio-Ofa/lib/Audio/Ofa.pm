package Audio::Ofa;
use strict;
use warnings;

use base qw(Exporter DynaLoader);

our $VERSION = '1.01';

__PACKAGE__->bootstrap($VERSION);

our @EXPORT_OK = qw(&ofa_get_version &ofa_create_print &OFA_LITTLE_ENDIAN &OFA_BIG_ENDIAN);


1

__END__

=head1 NAME

Audio::Ofa - Perl interface to libofa, an Acoustig Fingerprinting library

=head1 VERSION

This is version 1.01

=head1 SYNOPSIS

This module provides a direct interface to libofa.  For not-so-lowlevel and
more practical assistance with audio fingerprints see L<Audio::Ofa::Util>.

    use Audio::Ofa qw(ofa_get_version ofa_create_print);

=head1 SUBROUTINES

=head2 ofa_get_version

Retrieves the version of the installed libofa.  Returns a string like C<0.9.3>.

=head2 ofa_create_print(data, byteOrder, size, sRate, stereo)

From the libofa source code comments:

    data: a buffer of 16-bit samples in interleaved format (if stereo), i.e. L,R,L,R, etc.
                 This buffer is destroyed during processing.
                 Ideally, this buffer should contain the entire song to be analyzed, but the process will only
                 need the first 2min + 10sec + any silence prepending the actual audio. Since the precise silence
                 interval will only be known after a couple of processing steps, the caller must make adequate
                 allowance for this. Caveat emptor.
    byteOrder: OFA_LITTLE_ENDIAN, or OFA_BIG_ENDIAN - indicates the byte
               order of the data being passed in.
    size: the size of the buffer, in number of samples.
    sRate: the sample rate of the signal. This can be an arbitrary rate, as long as it can be expressed
                 as an integer (in samples per second). If this is different from 44100, rate conversion will
                 be performed during preprocessing, which will add significantly to the overhead.
    stereo: 1 if there are left and right channels stored, 0 if the data is mono
    
    On success, a valid text representation of the fingerprint is returned.

One should note that C<size> is the byte length of C<data> divided by 2 (as in 2
bytes as in 16 bit), regardless of C<stereo>.

The XS code will throw an exception if C<size> is too large, to prevent a buffer
overread.

=head1 CONSTANTS

=head2 OFA_LITTLE_ENDIAN

=head2 OFA_BIG_ENDIAN

=head1 SEE ALSO

L<Audio::Ofa::Util> provides utilities to read audio files and to look up
audio fingerprints at MusicDNS.

L<http://en.wikipedia.org/wiki/Audio_fingerprint> - The Wikipedia article about
acoustic fingerprints.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License (GPL) as published by the Free
Software Foundation (http://www.fsf.org/); either version 2 of the License, or
(at your option) any later version.

=cut
