package Audio::MPC;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use Fcntl qw/:seek/;

our $VERSION;
our @ISA = qw(Exporter);
our @EXPORT = qw(WAV_HEADER_SIZE MPC_LITTLE_ENDIAN MPC_BIG_ENDIAN);

sub Audio::MPC::Reader::read {
    my ($self, $bytes) = @_;
    read $self->fh, my ($buf), $bytes;
    return $buf;
}

sub Audio::MPC::Reader::seek {
    my ($self, $offset) = @_;
    return seek $self->fh, $offset, SEEK_SET;
}

sub Audio::MPC::Reader::tell {
    my ($self) = @_;
    return tell $self->fh;
}

sub Audio::MPC::Reader::get_size {
    my ($self) = @_;
    return -s $self->fh;
}

sub Audio::MPC::Reader::canseek {
    my ($self) = @_;
    return seek $self->fh, 0, SEEK_CUR;
}

BEGIN {
    # needs to happen early because of the 'use constant's below
    $VERSION = '0.04';
    require XSLoader;
    XSLoader::load('Audio::MPC', $VERSION);
}

# these constants are potentially used often,
# so it's better to turn them into real inlineable constants

use constant WAV_HEADER_SIZE	=> 44;
use constant MPC_LITTLE_ENDIAN	=> (constant("MPC_LITTLE_ENDIAN"))[1];
use constant MPC_BIG_ENDIAN	=> (constant("MPC_BIG_ENDIAN"))[1];

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Audio::MPC::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}


1;
__END__

=for changes stop

=head1 NAME

Audio::MPC - Perl extension for decoding musepack-encoded files

=head1 SYNOPSIS

    use Audio::MPC;
    use Fcntl qw/:seek/;
    
    my $mpc = Audio::MPC->new("file.mpc") or die Audio::MPC->errstr;
    
    open OUT, ">", "file.wav" or die $!;
    seek OUT, WAV_HEADER_SIZE, SEEK_SET;    # leave space for wave-header
    
    my $total;
    while ((my $num_bytes = $mpc->decode(my $buf)) > 0) {
	$total += $num_bytes;
	print OUT $buf;
    }

    # insert wave-header for $total bytes of data
    seek OUT, 0, SEEK_SET;
    print OUT $mpc->wave_header($total);
    close OUT;
	
=head1 DESCRIPTION

This module is a wrapper around libmpcdec that allows for decoding 
musepack-encoded digital audio. 

Musepack is a lossy audio-compression format optimized for higher bitrates.
See L<http://www.musepack.net/> for details.

=for readme stop

=head1 METHODS

=over 4

=item B<new> (file)

=item B<new> (filehandle-ref)

=item B<new> (Audio::MPC::Reader)

These construct a new C<Audio::MPC> object. The compressed audio-data will
either come from I<file>, I<filehandle-ref> or from an I<Audio::MPC::Reader>
object (see L</"Audio::MPC::Reader"> further below for details). 

Returns the newly created object or C<undef> in case of an error. In this case,
check C<< Audio::MPC->errstr >>.

=item B<decode> (buffer, [ MPC_LITTLE_ENDIAN || MPC_BIG_ENDIAN ])

Reads data from the audio-stream and puts the decoded PCM-samples into
I<buffer> which must not be readonly. The PCM data will be stereo (that is, two
channels) and 44.1 kHZ with each sample 16 bit wide.

The optional second argument specifies the byte-order of each sample. If not
specified, I<MPC_LITTLE_ENDIAN> is assumed.

Returns the length of I<buffer>, "0 but true" if the stream was succesfully
decoded with no more samples left and false in case of an error.

=item B<errstr>

This class method returns a string telling you what kind of error occured.
Currently, only use this method after the constructor C<new> failed to return a
new object.

=item B<wave_header> (length, [ MPC_LITTLE_ENDIAN || MPC_BIG_ENDIAN ])

Returns a wave file header suitable for I<length> bytes of data. The optional
second argument specifies the byte-order of the wave file and should match
the byte-order you specified in your calls to C<decode>. If ommitted, 
I<MPC_LITTLE_ENDIAN> is assumed.

See L</"SYNOPSIS"> for an example on how to use the C<decode> and
C<wave_header> couple.

=item B<seek_sample> (sample)

Seeks to the I<sample>-th sample in the audio-stream. 

Returns true on success, false otherwise.

=item B<seek_seconds> (second)

Seeks to the specified position in seconds.

Returns true on success, false otherwise.

=item B<length>

Returns the length of the audio-stream in seconds.

=item B<frequency>

Returns the sample frequency of the stream.

=item B<channels>

Returns number of channels of the stream.

=item B<header_pos>

Returns byte offset of the header's position in the stream.

=item B<version>

Returns this stream's version.

=item B<bps>

Returns bitrate per second of this stream. I have yet to find
a file where this method will not return 0.

=item B<average_bps>

Returns the average bitrate per second of this stream.

=item B<frames>

Returns the number of frames in this stream.

=item B<samples>

Returns the number of samples in this stream. Unfortunately, this
value cannot be used to precalculate the size of the resulting
PCM stream.

=item B<max_band>

Returns the maximum band-index used in this file (in the range 0 .. 31). 

=item B<is>

Returns true if intensitiy stereo is on. However, nowhere it is explained
what C<intensity stereo> is.

=item B<ms>

Returns true if mid/side stereo is on.

=item B<block_size>

This appears to be supported only on version 4 throughout 6 streams.

=item B<profile>

Returns an integer specifying the quality profile of this stream.

=item B<profile_name>

Returns the name of the quality profiled used for this stream.

=item B<gain_title>

Returns the replay gain title value.

=item B<gain_album>

Returns the replay gain album value.

=item B<peak_title>

Returns the peak title loudness level.

=item B<peak_album>

Returns the peak album loudness level.

=item B<is_gapless>

Returns true if this stream is gapless.

=item B<last_frame_samples>

Returns the number of valid samples in the last frame.

=item B<encoder_version>

Returns the version of the encoder this stream was encoded with.

=item B<encoder>

Returns the name of the encoder this was stream was encoded with.

=item B<tag_offset>

Returns the offset to the file tags.

=item B<total_length>

Returns the total length of the underlying file.

=back

=head1 Audio::MPC::Reader

Aside from a filename or a reference to a filehandle, C<< Audio::MPC->new >>
can also be fed an C<Audio::MPC::Reader> object. Such an object is a collection
of callback functions that get called by the decoding engine on the various
file operations, such as reading data or seeking in them.

=over 4

=item B<new> (filehandle, [ args ])

Constructs a new C<Audio::MPC::Reader> object:

    open my $fh, "file.mpc" or die $!;
    my $reader = Audio::MPC::Reader->new(
	$fh,
	read	    => \&my_read,
	seek	    => \&my_seek,
	tell	    => \&my_tell,
	get_size    => \&my_get_size,
	canseek	    => \&canseek,
	userdata    => { }, # arbitrary user data associated with the reader
    );

    my $mpc = Audio::MPC->new( $reader );

I<filehandle> is the only mandatory argument. If any of the other fields (or
even all of them) remain unspecified, C<Audio::MPC::Reader> will use its own
default handlers.

Each handler receives the C<Audio::MPC::Reader> object as its first argument.
To get at the filehandle, you call the C<fh> method on this object. Call
C<userdata> to retrieve the user data you associated with this reader.

The purpose and calling-convention for each handler is as follows:

=item * read (reader, size)

This is called when the decoder wants to acquire more data to decode. I<reader> is
the object as returned by C<< Audio::MPC::Reader->new >> and I<size> denotes the
number of bytes that should be read from the stream. The function is expected to
return the data read from the underlying filehandle.

    sub my_read {
	my ($reader, $size) = @_;
	read $reader->fh, my ($buf), $size;
	return $buf;
    }

=item * seek (reader, offset)

I<offset> is the byte position to seek to. The function is expected to return true
if the seek operation was succesful:

    sub my_seek {
	my ($reader, $offset) = @_;
	return seek $reader->fh, $offset, SEEK_SET;
    }

=item * tell (reader)

The function is expected to return the filepointer's current position in the stream:

    sub my_tell {
	my $reader = shift;
	return tell $reader->fh;
    }

=item * get_size (reader)

The function is expected to return the size of the complete data-stream:

    sub my_get_size {
	my $reader = shift;
	return -s $reader->fh;
    }

=item * canseek (reader)

The function is expected to return a true value if the underlying filehandle
is seekable. However, experiments showed that non-seekable streams cannot be
decoded and are therefore not handled at all:
    
    sub canseek {
	my $reader = shift;
	return seek $reader->fh, 0, SEEK_CUR;	# test if seek succeeded
    }

=back

=head1 EXPORT

These symbols are exported by default:

    WAV_HEADER_SIZE
    MPC_LITTLE_ENDIAN
    MPC_BIG_ENDIAN

=head1 BUGS AND LIMITATIONS

I am not aware of any outright bugs yet. 

A limitation of libmpcdec seems to be that you cannot decode from STDIN as it
is not seekable. It should however be possible to craft your own
C<Audio::MPC::Reader> object which maintains an internal character buffer as
userdata that can be used to fake up a seekable filehandle.

=for readme continue

=begin readme

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

Due to a subtle but unpleasant interaction between C++ method overloading and
the perl internals, you need at least perl5.8.0. 

You need a working C++ compiler and libmpcdec as available from L<http://www.musepack.net/>.
Furthermore:

    Test::More
    Test::LongString

=end readme

=begin changes

=head1 Revision history for Perl extension Audio::MPC

=over 4

=item * 0.04  Tue Mar  7 11:44:00 CEST 2006
 
    - updated to use libmpcdec who replaces libmusepack

=item * 0.03  Fri Sep 30 08:02:00 CEST 2005
 
    - there was a segfault when a file passed by filename
      could not be opened: fixed
    - errstr() method now includes $! when appropriate
    - fixed the SYNOPSIS section of the perldocs:
      the little script given in there now works

=item * 0.02  Mon May 16 13:13:58 CEST 2005

    - check.c had the wrong #include that would prevent
      installation on most systems

=item * 0.01  Wed May  4 08:30:27 2005

    - original version; created by h2xs 1.23 with options
	-b 5.6.0 -n Audio::MPC

=back

=end changes

=for changes stop

=head1 SEE ALSO

L<http://www.musepack.net/> 

=head1 VERSION

This is version 0.04.

=head1 AUTHOR

Tassilo von Parseval, E<lt>tassilo.von.parseval@rwth-aachen.deE<gt>

libmpcdec support patch by Sylvain Cresto, E<lt>scresto@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Tassilo von Parseval

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=for readme stop

=cut
