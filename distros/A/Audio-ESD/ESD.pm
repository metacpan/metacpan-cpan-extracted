# -*- cperl -*-

# Audio::ESD - Perl interface to the Enlightened Sound Daemon
#
# Copyright (c) 2000 Cepstral LLC. All rights Reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Written by David Huggins-Daines <dhd@cepstral.com>

package Audio::ESD;

use strict;
use Carp;
use IO::Socket;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader IO::Handle);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	ESD_ADPCM
	ESD_BITS16
	ESD_BITS8
	ESD_BUF_SIZE
	ESD_DEFAULT_PORT
	ESD_DEFAULT_RATE
	ESD_ENDIAN_KEY
	ESD_KEY_LEN
	ESD_LOOP
	ESD_MASK_BITS
	ESD_MASK_CHAN
	ESD_MASK_FUNC
	ESD_MASK_MODE
	ESD_MONITOR
	ESD_MONO
	ESD_NAME_MAX
	ESD_PLAY
	ESD_RECORD
	ESD_SAMPLE
	ESD_STEREO
	ESD_STOP
	ESD_STREAM
	ESD_VOLUME_BASE
);
%EXPORT_TAGS = (standard => \@EXPORT_OK);
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
		croak "Your vendor has not defined Audio::ESD macro $constname";
	}
    }
    no strict 'refs';
    if ($] >= 5.00561) {
	*$AUTOLOAD = sub () { $val };
    } else {
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

bootstrap Audio::ESD $VERSION;

sub _get_format_bits {
    my ($channels, $bits, $encoding) = @_;

    $channels ||= 1;
    $bits ||= 16;
    $encoding ||= 'linear';

    my $fmt = 0;
    if ($channels == 1) {
	$fmt |= ESD_MONO(); # argh hate kill h2xs die die die
    } elsif ($channels == 2) {
	$fmt |= ESD_STEREO();
    } else {
	croak "Unsupported number of channels $channels\n";
    }

    if ($encoding eq 'linear') {
	if ($bits == 8) {
	    $fmt |= ESD_BITS8();
	} elsif ($bits == 16) {
	    $fmt |= ESD_BITS16();
	} else {
	    croak "Unsupporte sample size $bits\n"
	}
    } else {
	croak "Unsupported encoding $encoding\n";
    }

    return $fmt;
}

sub _make_esd_stream {
    my ($func, $fmt, $opts) = @_;

    $fmt |= _get_format_bits($opts->{channels}, $opts->{bits_sample},
			     $opts->{encoding});
    my $sps = $opts->{sample_rate} || $opts->{sps} || 16000;
    my $fd = $func->($fmt, $sps, $opts->{host}, $opts->{name})
	or return undef;
    return IO::Handle->new_from_fd($fd, "r+");
}

# Bizarro-constructors of various sorts.
#
# I'm not really sure what the bad side effects of reblessing an
# IO::Handle into Audio::ESD are, but it does seem to work okay.

sub play_stream {
    my ($this, $opts) = @_;
    my $class = ref $this || $this;

    $opts ||= {};
    my $func = ($opts->{fallback} ?
		\&esd_play_stream_fallback : \&esd_play_stream);
    my $fh = _make_esd_stream($func, ESD_PLAY(), $opts)
	or return undef;
    bless $fh, $class;
}

sub record_stream {
    my ($this, $opts) = @_;
    my $class = ref $this || $this;

    $opts ||= {};
    my $func = ($opts->{fallback} ?
		\&esd_record_stream_fallback : \&esd_record_stream);
    my $fh = _make_esd_stream($func, ESD_RECORD(), $opts)
	or return undef;
    bless $fh, $class;
}

sub monitor_stream {
    my ($this, $opts) = @_;
    my $class = ref $this || $this;

    $opts ||= {};
    my $fh = _make_esd_stream(\&esd_monitor_stream,
			      ESD_PLAY(), # ???
			      $opts) or return undef;
    bless $fh, $class;
}

sub filter_stream {
    my ($this, $opts) = @_;
    my $class = ref $this || $this;

    $opts ||= {};
    my $fh = _make_esd_stream(\&esd_filter_stream,
			      ESD_PLAY(), # ???
			      $opts) or return undef;
    bless $fh, $class;
}

sub open_server {
    my ($this, $host) = @_;
    my $class = ref $this || $this;

    my $fd = esd_open_sound($host)
	or return undef;
    my $sock = IO::Handle->new_from_fd($fd, "r+")
	or return undef;

    bless $sock, $class;
}

1;
__END__

=head1 NAME

Audio::ESD - Perl extension for talking to the Enlightened Sound Daemon

=head1 SYNOPSIS

  use Audio::ESD;
  my $stream = Audio::ESD->play_stream({ # these are the defaults
                                         sample_rate => 16000,
                                         channels => 1,
                                         fallback => 0,
                                         bits_sample => 16,
                                         encoding => 'linear' })
      or die "Failed to open ESD stream: $!\n";
  print $stream $data; # etcetera

=head1 DESCRIPTION

This module provides a Perl wrapper around the Enlightened Sound
Daemon's client library.  Input, output, and monitoring streams are
supported, as well as some (but not all) of the control functions.
Samples are supported but untested.

=head1 AUDIO STREAMS

Audio streams can be opened for playback, recording, monitoring, or
filtering.  There are separate `constructor' class methods for doing
all of these things.  All of these methods accept a single optional
argument, which is a reference to a hash possibly containing the
following stream parameters (defaults are supplied if the parameters
are not present):

=over 4

=item B<sample_rate>

The sampling rate for audio written to and/or read from the stream,
expressed in samples per second.  Defaults to 16000

=item B<bits_sample>

The sample size in bits.  Currently acceptable values are 8 and 16.
Defaults to 16.

=item B<channels>

The number of channels (interleaved).  Currently acceptable values are
1 and 2.  Defaults to 1.

=item B<encoding>

The audio encoding format used.  The only currently acceptable value
is 'linear' (which means linear PCM).  Maybe someday Esound will
support others.

=back

To open a stream for playback, use B<play_stream>:

  my $stream = Audio::ESD->play_stream(\%opts);

This method also supports an extra option, 'fallback'.  If this is
true, the Esound library will "fall back" to the local audio device if
a connection to the ESD server could not be made (or so the
documentation says, at least).

To open a stream for recording, use B<record_stream>:

  my $stream = Audio::ESD->record_stream(\%opts);

This method also supports the 'fallback' option.

To open a stream for monitoring (i.e. capturing the mixed output
stream from the server), use B<monitor_stream>:

  my $stream = Audio::ESD->monitor_stream(\%opts);

To open a stream for filtering, use B<filter_stream>:

  my $stream = Audio::ESD->filter_stream(\%opts);

Apparently, this allows you read blocks of data from the output
stream, do some transformations on them, then write them back, and
have ESD play them.

=head1 SERVER CONNECTIONS

To open a general-purpose control connection to the ESD server, use
the B<open_sound> class method:

  my $esd = Audio::ESD->open_sound($hostname);

If C<$hostname> is undefined, a local ESD will be contacted via a Unix
domain socket.

As with the audio streams, you can read and write to this connection
as if it were a normal filehandle (since, in fact, that is what it
is...)  and thus, if you want to take your chances with the
"over-the-wire" protocol you are free to do so.

However, you most likely just want to use this connection to access
various parameters in the server, and don't worry, there are some
methods for that:

=over 4

=item B<send_auth>

  $esd->send_auth();

=item B<lock>

  $esd->lock();

=item B<unlock>

  $esd->unlock();

=item B<standby>

  $esd->standby();

=item B<resume>

  $esd->resume();

=item B<sample_cache>

  $esd->sample_cache($format, $rate, $length, $name);

=item B<confirm_sample_cache>

  $esd->confirm_sample_cache();

=item B<sample_getid>

  my $sample_id = $esd->sample_getid($name);

=item B<sample_play>

  $esd->sample_play($sample_id);

=item B<sample_loop>

  $esd->sample_loop($sample_id);

=item B<sample_stop>

  $esd->sample_stop($sample_id);

=item B<sample_free>

  $esd->sample_free($sample_id);

=item B<set_stream_pan>

  $esd->set_stream_pan($stream_id, $left_scale, $right_scale);

=item B<set_default_sample_pan>

  $esd->set_default_sample($stream_id, $left_scale, $right_scale);

=item B<get_latency>

  my $latency = $esd->get_latency();

=item B<get_standby_mode>

  my $standby = $esd->get_standby_mode();

=back

=head1 SERVER INFO

=over 4

=item B<get_server_info>

  my $server_info = $esd->get_server_info();

=item B<get_all_info>

  my $info = $esd->get_all_info();

=back

=over 4

=item B<print_server_info>

  $server_info->print_server_info();

=item B<print_all_info>

  $info->print_all_info();

=back

=head1 EXPORTABLE CONSTANTS

The following constants can be imported from C<Audio::ESD>.  They are
mostly useful for the B<format> argument to some functions.  You can
import all of them with the B<:standard> tag.

	ESD_ADPCM
	ESD_BITS16
	ESD_BITS8
	ESD_BUF_SIZE
	ESD_DEFAULT_PORT
	ESD_DEFAULT_RATE
	ESD_ENDIAN_KEY
	ESD_KEY_LEN
	ESD_LOOP
	ESD_MASK_BITS
	ESD_MASK_CHAN
	ESD_MASK_FUNC
	ESD_MASK_MODE
	ESD_MONITOR
	ESD_MONO
	ESD_NAME_MAX
	ESD_PLAY
	ESD_RECORD
	ESD_SAMPLE
	ESD_STEREO
	ESD_STOP
	ESD_STREAM
	ESD_VOLUME_BASE

=head1 BUGS

It probably leaks file descriptors or worse.  Lots of stuff is
untested and undocumented, and since the Esound API is full of happy
surprises it's likely not to work.

=head1 AUTHOR

David Huggins-Daines <dhd@cepstral.com>

=head1 SEE ALSO

perl(1), esd(1).

=cut
