package Audio::DSP;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(AFMT_A_LAW
             AFMT_IMA_ADPCM
             AFMT_MPEG
             AFMT_MU_LAW
             AFMT_QUERY
             AFMT_S16_BE
             AFMT_S16_LE
             AFMT_S16_NE
             AFMT_S8
             AFMT_U16_BE
             AFMT_U16_LE
             AFMT_U8
            );

$VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {
            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        }
        else {
                croak "Your vendor has not defined Audio::DSP macro $constname";
        }
    }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

bootstrap Audio::DSP $VERSION;

1;
__END__

=head1 NAME

Audio::DSP - Perl interface to *NIX digital audio device.

=head1 SYNOPSIS

    use Audio::DSP;

    ($buf, $chan, $fmt, $rate) = (4096, 1, 8, 8192);

    $dsp = new Audio::DSP(buffer   => $buf,
                          channels => $chan,
                          format   => $fmt,
                          rate     => $rate);

    $seconds = 5;
    $length  = ($chan * $fmt * $rate * $seconds) / 8;

    $dsp->init() || die $dsp->errstr();

    # Record 5 seconds of sound
    for (my $i = 0; $i < $length; $i += $buf) {
        $dsp->read() || die $dsp->errstr();
    }

    # Play it back
    for (;;) {
        $dsp->write() || last;
    }

    $dsp->close();

=head1 DESCRIPTION

Audio::DSP is built around the OSS (Open Sound System) API and allows perl to
interface with a digital audio device. It provides, among other things, an
L<initialization|"item_init"> method which opens and handles ioctl messaging
on the audio device file. Audio::DSP also provides some L<rudimentary methods|"Dealing with data in memory">
for the storage and manipulation of audio data in memory.

In order to use Audio::DSP, you'll need to have the necessary OSS
drivers/libraries installed. OSS is available for many popular Unices, and a
GPLed version (with which this extension was initially developed and tested) is
distributed with with the Linux kernel.

=head1 CONSTRUCTOR

=over 4

=item new([params])

Returns blessed Audio::DSP object. Parameters:

=over 4

=item device

Name of audio device file. Default is '/dev/dsp'.

=item buffer

Length of buffer, in bytes, for reading from/writing to the audio device file.
Default is 4096.

=item rate

Sampling rate in bytes per second. This parameter affects, among other things,
the highest frequency in the sampled signal, which must be less than half the
sample rate. Compact discs use a 44100 samples per second sampling rate.

Default sample rate is 8192.

=item format

Sample format. This parameter affects not only the size and the byte-order of
a sample, but also its dynamic range.

Sample format may be directly specified as an integer (e.g. 8 or 16) or as one
of the format L<constants|"CONSTANTS"> defined in soundcard.h and exported by
Audio::DSP on use. The latter is preffered; an integer value of 16 (for
example) corresponds to little endian signed 16 (AFMT_S16_LE), which format
may or may not work with your card. So be careful.

If the format constant is passed as a string (e.g. 'AFMT_U8' rather than
AFMT_U8), it will work, but B<this feature is deprecated>. It has been
retained for backward-compatibility, but do not assume that it will be present
in future versions.

Default sample format is AFMT_U8.

=item channels

1 (mono) or 2 (stereo). Default is 1.

=item file

File from which to read raw sound data to be stored in memory.

No effort is made to interpret the type of file being read. It's up
to you to set the appropriate rate, channel, and format parameters if you
wish to write the sound data to your audio device without damaging your
hearing.

=back

=back

=head1 METHODS

=head2 Opening and closing the device

=over 4

=item init([params])

Opens and initializes audio device file. Parameters L<device|"item_device">,
L<buffer|"item_buffer">, L<rate|"item_rate">, L<format|"item_format">, and
L<channels|"item_channels"> are shared with the constructor, and will override
them. Additional parameters:

=over 4

=item mode

Integer mode in which to open audio device file. Specifying the modes 'O_RDWR',
'O_RDONLY', and 'O_WRONLY' as strings will work, but B<this feature is
deprecated>. Use the Fcntl.pm constants to obtain the approriate integer mode
values instead.

The default value is O_RDWR.

=back

Example:

    $dsp->init(mode => O_RDONLY) || die $dsp->errstr();

Returns true on success, false on error.

=item open([mode])

Opens audio device file, does not send any ioctl messages. Default mode is
O_RDWR.

Example:

    $dsp->open(O_RDONLY) || die $dsp->errstr();

Returns true on success, false on error.

=item close()

Closes audio device file. Returns true on success, false on error.

=back

=head2 Dealing with data in memory

=over 4

=item audiofile($filename)

Reads data from specified file and stores it in memory. If there
is sound data stored already in memory, the file data will be concatenated
onto the end of it.

No effort is made to interpret the type of file being read. It's up
to you to set the appropriate rate, channel, and format parameters if you
wish to write the sound data to your audio device without damaging your
hearing.

    $dsp->audiofile('foo.raw') || die $dsp->errstr();

Returns true on success, false on error.

=item read()

Reads buffer length of data from audio device file and appends it to the
audio data stored in memory. Returns true on success, false on
error.

=item write()

Writes buffer length of sound data currently stored in memory,
starting at the current L<play mark|"item_setmark"> offset, to audio device
file. L<Play mark|"item_setmark"> is incremented one buffer length. Returns
true on success, false on error or if the L<play mark|"item_setmark"> exceeds
the length of audio data stored in memory.

=item clear()

Clears audio data currently stored in memory, sets play mark to
zero. No return value.

=item data()

Returns sound data stored in memory.

    open RAWFILE, '>foo.raw';
    print RAWFILE $dsp->data();
    close RAWFILE;

=item datacat($data)

Concatenates argument (a string) to audio data stored in memory.
Returns length of audio data currently stored.

=item datalen()

Returns length of audio data currently stored in memory.

=item setbuffer([$length])

Sets read/write buffer if argument is provided.

Returns buffer length currently specified.

=item setmark([$mark])

Sets play mark if argument is provided. The play mark indicates how many bites
of audio data stored in memory have been written to the audio device file
since the mark was last set to zero. This lets the
L<write()|"item_write"> method know what to write.

Returns current play mark.

=back

=head2 Reading/writing data directly to/from the device

These methods are provided mainly for the purposes of anyone wishing to delve
into hard-disk recording.

=over 4

=item dread([$length])

Reads length of data from audio device file and returns it. If length is not
supplied, a "buffer length" of data (as specified when the L<constructor|"item_new">/L<init()|"item_init"> method was called) is read.
If there is an error reading from the device file, a false value is returned.

=item dwrite($data)

Writes data directly to audio device. Returns true on success, false on
error.

=back

=head2 I/O Control

The device must be opened with L<init()|"item_init"> or 
L<open()|"item_open"> before calling any of the following methods.

It is important to set sampling parameters in the following order:
L<setfmt()|"item_setfmt">, L<channels()|"item_channels">,
L<speed()|"item_speed">. Setting sampling rate (speed) before number of
channels does not work with all devices, according to OSS documentation. The
safe alternative is to call L<init()|"item_init"> with the appropriate
parameters.

=over 4

=item post()

Sends SNDCTL_DSP_POST ioctl message to audio device file. Returns true on
success, false on error.

=item reset()

Sends SNDCTL_DSP_RESET ioctl message to audio device file. Returns true on
success, false on error.

=item sync()

Sends SNDCTL_DSP_SYNC ioctl message to audio device file. Returns true on
success, false on error.

=item setfmt($format)

Sends SNDCTL_DSP_SETFMT ioctl message to audio device file, with sample format
as argument. Returns sample format to which the device was actually
set if successful, false on error. You should check the return value even on
success to ensure the requested sample format was in fact set for the device.

    my $format = AFMT_S16_LE; # signed 16-bit, little-endian
    my $rv     = $dsp->setfmt($format) || die $dsp->errstr;

    die "Failed to set requested sample format"
        unless ($format == $rv);

=item channels($channels)

Sends SNDCTL_DSP_CHANNELS ioctl message to audio device file, with
number of channels as argument. Returns number of channels to which the device
was actually set if successful, false on error. You should check the return
value even on success to ensure the requested number of channels were in fact
set for the device.

    my $chan = 2; # stereo
    my $rv   = $dsp->channels($chan) || die $dsp->errstr;

    die "Failed to set requested number of channels"
        unless ($chan == $rv);

=item speed($rate)

Sends SNDCTL_DSP_SPEED ioctl message to audio device file, with
sample rate as argument. Returns sample rate to which the device was actually
set if successful, false on error. You should check the return value even on
success to ensure the requested sample rate was in fact set for the device.

    my $rate = 44100; # CD-quality sample rate
    my $rv   = $dsp->speed($rate) || die $dsp->errstr;

    die "Failed to set requested sample rate"
        unless ($rate == $rv);

=item setduplex()

Sends SNDCTL_DSP_SETDUPLEX ioctl message to audio device file. Returns true on
success, false on error.

=back

=head2 Misc

=over 4

=item errstr()

Returns last recorded error.

=back

=head2 Deprecated methods

The following methods exist for transitional compatibility with version 0.01
and may not be available in future versions.

The preferred alternative to the set* methods below is either to:

=over 4

=item 1. close the device and call L<init()|"item_init"> with the appropriate
parameters or:

=item 2. call the appropriate I/O control methods after having
closed/re-opened the device, or after having called L<reset()|"item_reset">

=back

The second should only be performed if you know what you are doing. It is
important, for example, to set sampling parameters in the following order:
L<setfmt()|"item_setfmt">, L<channels()|"item_channels">,
L<speed()|"item_speed">. Setting sampling rate (speed) before number of
channels does not work with all devices, according to OSS documentation.

=over 4

=item getformat($format)

Returns true if specified L<sample format|"item_format"> is supported by audio
device. A false value may indicate the format is not supported, but it may also
mean that the SNDCTL_DSP_GETFMTS ioctl failed (the
L<init()|"item_init"> method must be called before this method), etc.
Be sure to check the last L<error message|"item_errstr"> in this case.

B<Deprecated>. If you wish to check if a given format is supported by the
device, instead call L<getfmts()|"item_getfmts"> method, then AND the return value with the
format for which you wish to check.

    my $format = AFMT_S16_LE;
    my $mask   = $dsp->getfmts;

    print "Format is supported!\n"
        if ($format & $mask);

=item queryformat()

Returns currently used format of initialized audio device. Unlike the
L<setformat()|"item_setformat"> method, queryformat "asks" the audio
device directly which format is being used.

B<Deprecated>. If you wish to find the format to which the device is currently
set, instead call L<setfmt()|"item_setfmt"> with AFMT_QUERY as an argument and check the return
value.

    my $format = $dsp->setfmt(AFMT_QUERY);
    print "Device set to format $format.\n";

=item setchannels([$channels])

B<Deprecated>. See introduction to this section for alternative methods.

Sets number of channels if argument is provided. If the audio device file is
open, the number of channels will not actually be changed until you call
L<close()|"item_close"> and L<init()|"item_init"> again.

Returns number of channels currently specified.

=item setdevice([$device_name])

B<Deprecated>. See introduction to this section for alternative methods.

Sets audio device file if argument is provided. If the device is open, it will
not actually be changed until you call L<close()|"item_close">
and L<init()|"item_init"> again.

Returns audio device file name currently specified.

=item setformat([$bits])

B<Deprecated>. See introduction to this section for alternative methods.

Sets sample format if argument is provided. If the audio device file is open,
the sample format will not actually be changed until you call
L<close()|"item_close"> and L<init()|"item_init"> again.

Returns sample format currently specified.

=item setrate([$rate])

B<Deprecated>. See introduction to this section for alternative methods.

Sets sample rate if argument is provided. If the audio device file is open,
the sample rate will not actually be changed until you call
L<close()|"item_close"> and L<init()|"item_init"> again.

Returns sample rate currently specified.

=back

=head1 CONSTANTS

The following audio-format constants are exported by Audio::DSP on use:

=over 4

=item AFMT_MU_LAW

logarithmic mu-Law

=item AFMT_A_LAW

logarithmic A-Law

=item AFMT_IMA_ADPCM

4:1 compressed (IMA)

=item AFMT_U8

8 bit unsigned

=item AFMT_S16_LE

16 bit signed little endian (Intel - used in PC soundcards)

=item AFMT_S16_BE

16 bit signed big endian (PPC, Sparc, etc)

=item AFMT_S8

8 bit signed

=item AFMT_U16_LE

16 bit unsigned little endian

=item AFMT_U16_BE

16 bit unsigned bit endian

=item AFMT_MPEG

MPEG (not currently supported by OSS)

=back

=head1 NOTES

Audio::DSP does not provide any methods for converting the raw audio data
stored in memory into other formats (that's another project altogether).
You can, however, use the L<data()|"item_data"> method to dump the
raw audio to a file, then use a program like sox to convert it to your
favorite format. If you are interested in writing .wav files, you may want to
take a look at Nick Peskett's Audio::Wav module.

=head1 AUTHOR

Seth David Johnson, seth@pdamusic.com

=head1 SEE ALSO

Open Sound System homepage:

    http://www.opensound.com/

Open Sound System - Audio programming:

    http://www.opensound.com/pguide/audio.html

OSS Programmer's guide (PDF):

    http://www.opensound.com/pguide/oss.pdf

A GPLed version of OSS distributed with the Linux kernel was used in the
development of Audio::DSP. See "The Linux Sound Subsystem":

    http://www.linux.org.uk/OSS/

To my knowledge, the Advanced Linux Sound Architecture (ALSA) API is supposed
to remain compatible with the OSS API on which this extension is built. ALSA
homepage:

    http://www.alsa-project.org/

perl(1).

=head1 COPYRIGHT

Copyright (c) 1999-2000 Seth David Johnson.  All Rights Reserved. This program
is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself.

=cut
