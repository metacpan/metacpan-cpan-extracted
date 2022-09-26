package Audio::StreamGenerator;

use strict;
use warnings;
use Carp;

our $VERSION = '1.01';

use constant {
    MAXINT => 32767
};

sub debug {
    my ($self, $message) = @_;
    return unless $self->{debug};
    if (ref $self->{debug} eq 'CODE') {
        $self->{debug}->($message)
    }
    else {
        print STDERR $message . "\n";
    }
}

sub new {
    my ( $class, %args ) = @_;

    my %defaults = (
        buffer_length_seconds       => 10,
        normal_fade_seconds         => 5,
        skip_fade_seconds           => 3,
        sample_rate                 => 44100,
        channels_amount             => 2,
        max_vol_before_mix_fraction => 0.75,
        min_audible_vol_fraction    => 0.005,
        debug                       => 0,
    );

    my @mandatory_keys = qw (
        get_new_source
        out_fh
    );

    my @optional_keys = qw(
        run_every_second
        debug
    );

    foreach my $key (@mandatory_keys) {
        croak "value for $key is missing" if !defined( $args{$key} );
    }
    my %key_lookup = map { $_ => 1 } ( @mandatory_keys, @optional_keys );

    foreach my $key ( keys %args ) {
        croak "unknown argument '$key'"
            if !defined( $key_lookup{$key} );
    }

    my %self = ( %defaults, %args{ @mandatory_keys, @optional_keys } );

    bless \%self, $class;
}

sub get_streamer {
    my ($self, $batch_length_seconds) = @_;
    my $batch_size = int(($batch_length_seconds || 1) * $self->{sample_rate});

    $self->debug( "starting stream" );

    $self->{source} = $self->_do_get_new_source();
    $self->{buffer} = [];
    $self->{skip}   = 0;
    my $eof = undef;
    my $last_elapsed = 0;

    return sub {
        $eof = eof( $self->{source} ) unless defined $eof;
        if ( $eof || $self->{skip} ) {
            $last_elapsed = 0;
            $eof = undef;
            $self->_mix();
        }

        my $needed = $self->{buffer_length_seconds} * $self->{sample_rate};
        my $diff = @{ $self->{buffer} } - $needed;

        if ($diff < 0) {
            $eof = 1 unless $self->_get_samples($batch_size, $self->{buffer});
        }
        else {
            $self->_send_samples($batch_size);

            if (defined $self->{run_every_second}) {
                my $current_elapsed = int( $self->get_elapsed_seconds );
                if ($current_elapsed > $last_elapsed) {
                    $self->{run_every_second}($self);
                    $last_elapsed = $current_elapsed;
                }
            }
        }
    };
}

sub _mix {
    my $self = shift;

    my $buffer = $self->{buffer};

    # We're done with the old source
    close( $self->{source} );

    $self->_make_mixable($buffer);

    my @skipped_buffer;

    if ( $self->{skip} ) {
        # In case of a requested 'skip', we need to remove a few seconds from the end of the (old) buffer because
        # we want a 'skip' mix to be shorter than a normal mix between 2 tracks - both because we
        # are still in the middle of the old song, so the mix does not sound 'natural' - and because the
        # user probably wants to switch to the new track a.s.a.p.
        #
        # Also, fade out the old track.
        #
        $self->{skip} = 0;
        $self->debug( "shortening buffer for skip..." . scalar(@$buffer) );
        splice @$buffer, ( $self->{skip_fade_seconds} * $self->{sample_rate} );

        my $index = 0;
        foreach my $sample (@$buffer) {
            my $togo = @$buffer - $index;
            my $fraction = $togo / @$buffer;
            for my $channel (0 .. @$sample - 1) {
                $sample->[$channel] *= $fraction;
            }
            $index++;
        }
    }
    else {
        # In case the old track was very short (a few seconds, shorter than the current buffer we are trying to mix),
        # there may still be audio from the previous old track in the buffer.
        # In this case, skip to the beginning of the current old track, and keep the 'skipped' samples in @skipped_buffer,
        # so we can re-add them to the beginning of the buffer after mixing is done.
        #
        # If we don't do this, this sequence:
        # old song -> very short jingle -> new song
        # Can result in the new song starting before the jingle.

        my $to_skip = @$buffer - $self->{elapsed};
        push (@skipped_buffer, splice(@$buffer, 0, $to_skip) ) if $to_skip > 0;
    }

    # Open the new track. We are not going to read from it yet, but opening it now may give the child process some time to start up.
    $self->{source} = $self->_do_get_new_source();

    # Find the index of the last sample that is 'audible' (loud enough to hear) in the remaining buffer of the old source.
    #
    # The audio stream is a 'wave' expressed as a signed integer - so 0 is 'silence'.
    # Use abs() to compare samples with value < 0 with those > 0
    #
    my $last_audible_sample_index;
    my $audible_threshold      = MAXINT * $self->{min_audible_vol_fraction};

    FIND_LAST_AUDIBLE: foreach my $index (reverse 0 .. @$buffer - 1) {
        my $sample = $buffer->[$index];
        foreach my $channel(0 .. $self->{channels_amount} - 1) {
            if (abs($sample->[$channel]) >= $audible_threshold) {
                $last_audible_sample_index = $index;
                last FIND_LAST_AUDIBLE;
            }
        }
    }

    if (defined $last_audible_sample_index) {
        $self->debug( "last audible sample index: $last_audible_sample_index of " . scalar( @$buffer ) );

        # remove everything after the 'last audible' sample from the remaining buffer of the old source
        # in other words, remove silence at the end of the track.
        splice @$buffer, $last_audible_sample_index + 1
    }
    else {
        $self->debug( "no audible samples in buffer?! - buffer size is " . scalar(@$buffer));
        @$buffer = ();
    }

    # We only want the mix to last normal_fade_seconds seconds. So skip the samples in the remaining old buffer that are too much.
    $self->debug("buffer size before sizing down:" . scalar(@$buffer));
    my $to_size_down = @$buffer - ($self->{normal_fade_seconds} * $self->{sample_rate});
    push(@skipped_buffer, splice(@$buffer, 0, $to_size_down) ) if $to_size_down > 0;
    $self->debug("buffer size after sizing down:". scalar(@$buffer));


    # Find the index of the last sample that is 'loud' (too loud to mix) in the remaining buffer of the old source.
    my $last_loud_sample_index;
    my $loud_threshold         = MAXINT * $self->{max_vol_before_mix_fraction};
    FIND_LAST_LOUD: foreach my $index (reverse 0 .. @$buffer - 1) {
        my $sample = $buffer->[$index];
        foreach my $channel (0 .. $self->{channels_amount} - 1) {
            if ( abs($sample->[$channel]) >= $loud_threshold ) {
                $last_loud_sample_index = $index;
                last FIND_LAST_LOUD;
            }
        }
    }

    # Skip everything up to and including the last loud sample
    if (defined $last_loud_sample_index) {
        $self->debug( "last loud sample index: $last_loud_sample_index of " . scalar( @$buffer ) );
        push(@skipped_buffer, splice(@$buffer, 0, $last_loud_sample_index + 1));
    }
    else {
        $self->debug( "no loud samples in the old track");
    }

    # get as many samples from the new source as we have left from the old source,
    # or in case of a very short new track, as many as possible.
    my @new_buffer;
    $self->_get_samples(scalar @$buffer, \@new_buffer);
    $self->_make_mixable(\@new_buffer);

    # If the new track is shorter than the remaining buffer of the old track
    # (so the new track is only a few seconds long), skip the extra samples in the old buffer.
    # This prevents situations where we play a very short jingle and then hear another
    # few remaining seconds of the 'old' track.
    if (@$buffer > @new_buffer) {
        my $to_skip = @$buffer - @new_buffer;
        push @skipped_buffer, splice(@$buffer, 0, $to_skip);
    }

    my @max   = (0) x $self->{channels_amount};
    my $index = -1;

    # Loop over the remaining samples in the buffer of the old source
    foreach my $sample (@$buffer) {
        $index++;

        # only log at full seconds - don't flood the log
        if ( defined $self->{debug} && !( $index % $self->{sample_rate} ) ) {
            my $full_second = $index / $self->{sample_rate};
            $self->debug( "mixing second $full_second..." );
        }

        # Do the actual mix: simply add up the values of the samples of the old & new track.
        # Keep track of the loudest sample value per channel. We use it later on for volume adjustment.

        my $newsample = shift @new_buffer;
        foreach my $channel (0 .. $self->{channels_amount} - 1) {
            $sample->[$channel] += $newsample->[$channel];
            my $value = abs($sample->[$channel]);
            if ( $value > $max[$channel] ) {
                $max[$channel] = $value;
            }
        }
    }

    $self->debug( "done mixing" );
    croak "unused samples left in the buffer of the new track after mixing - this should never happen!" if @new_buffer;

    # re-add the samples we may have skipped before mixing to the beginning of the buffer.
    unshift( @$buffer, @skipped_buffer );

    # Volume adjustment
    #
    # In case there are any samples in the "mixed buffer" that are louder than MAXINT,
    # lower the volume of the *whole* buffer just enough that it will stay within the limits.
    # To minimise audible impact, this happens for each channel separately.
    #
    # This is a bit of a naive approach - in theory this could lead to an audible drop in volume
    # just before mixing. In practice the audible impact seems to be minimal.
    #
    # We might be able to further improve this by doing the volume adjustment more gradually - but this seems complicated.
    #
    foreach my $channel ( grep { $max[$_] > MAXINT } (0 .. $self->{channels_amount} - 1) ) {
        $self->debug( "channel $channel needs volume adjustment" );

        foreach my $sample ( @$buffer ) {
            $sample->[$channel] =
                ( $sample->[$channel] / $max[$channel] ) * MAXINT;
        }
    }
}

sub _make_mixable {
    my ($self, $buffer) = @_;
    @$buffer = map { $self->_unpack_sample($_) } @$buffer;
}


sub stream {
    my $self = shift;
    my $streamer = $self->get_streamer;

    while (1) {
        $streamer->();
    }
}

sub get_elapsed_samples {
    my $self = shift;
    return $self->{elapsed};
}

sub get_elapsed_seconds {
    my $self = shift;
    return $self->{elapsed} / $self->{sample_rate};
}

sub _send_samples {
    my ($self, $count) = @_;
    return unless $count;

    my @samples = $self->_pack_samples(splice @{ $self->{buffer} }, 0, $count);

    print {$self->{out_fh}} @samples;
}

sub _pack_samples {
    my ($self, @samples) = @_;

    return map { $self->_pack_sample($_) } @samples;
}

sub _pack_sample {
    my ($self, $sample) = @_;

    return map { pack 's', $_ } @$sample
        if ref $sample eq 'ARRAY';
    return $sample;
}

sub _unpack_sample {
    my ($self, $sample) = @_;

    return $sample unless defined $sample;
    return $sample if ref $sample eq 'ARRAY';
    return [unpack 's*', $sample];
}

sub _get_samples {
    my ($self, $count, $dest) = @_;
    return 1 unless $count;

    my $data;
    my $bytes_div = $self->{channels_amount} * 2;
    my $bytes = $bytes_div * $count;
    my $len   = read( $self->{source}, $data, $bytes );

    if ( my $rest = $len % $bytes_div ) {
        my $add_bytes = $bytes_div - $rest;
        $data .= "\x00" x $add_bytes;
        $len += $add_bytes;
    }

    $self->{elapsed} += ( $len / $bytes_div );

    while ($data) {
        push @$dest, substr $data, 0, $bytes_div, '';
    }

    return $len;
}

sub _do_get_new_source {
    my $self = shift;
    $self->{elapsed} = 0;
    return $self->{get_new_source}();
}

sub skip {
    my $self = shift;
    $self->{skip} = 1;
}

1;

__END__

=pod

=head1 NAME

Audio::StreamGenerator - create a 'radio' stream by mixing ('cross fading') multiple audio sources (files or anything that can be converted to PCM audio) and sending it to a streaming server (like Icecast)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Audio::StreamGenerator;

    my $out_command = q~
            ffmpeg -re -f s16le -acodec pcm_s16le -ac 2 -ar 44100 -i -  \
            -acodec libopus -ac 2 -b:a 160k -content_type application/ogg -format ogg icecast://source:hackme@localhost:8000/our_radio.opus \
            -acodec libmp3lame -ac 2 -b:a 192k -content_type audio/mpeg icecast://source:hackme@localhost:8000/our_radio.mp3 \
            -acodec aac -b:a 192k -ac 2 -content_type audio/aac icecast://source:hackme@localhost:8000/our_radio.aac
    ~;

    my $out_fh;
    open ($out_fh, '|-', $out_command);

    sub get_new_source {
        my $fullpath = '/path/to/some/audiofile.flac';
        my @ffmpeg_cmd = (
                '/usr/bin/ffmpeg',
                '-i',
                $fullpath,
                '-loglevel', 'quiet',
                '-f', 's16le',
                '-acodec', 'pcm_s16le',
                '-ac', '2',
                '-ar', '44100',
                '-'
        );
        open(my $source, '-|', @ffmpeg_cmd);
        return $source;
    }

    sub run_every_second {
        my $streamert = shift;
        my $position = $streamert->get_elapsed_seconds();
        print STDERR "now at position $position\r";
        if ([-some external event happened-]) {  # skip to the next song requested
            $streamert->skip()
        }
    }

    my $streamer = Audio::StreamGenerator->new(
        out_fh => $out_fh,
        get_new_source => \&get_new_source,
        run_every_second => \&run_every_second,
    );

    $streamer->stream();

=head1 DESCRIPTION

This module creates a 'live' audio stream that can be broadcast using streaming technologies like Icecast or HTTP Live Streaming.

It creates one ongoing audio stream by mixing or 'crossfading' multiple sources (normally audio files).

Although there is nothing stopping you from using this to generate a file that can be played back later, its intended use is to create a 'radio' stream that can be streamed or 'broadcast' live on the internet.

The module takes raw PCM audio from a file handle as input, and outputs raw PCM audio to another file handle. This means that an external program is necessary to decode (mp3/flac/etc) source files, and to encode & stream the actual output. For both purposes, ffmpeg is recommended - but anything that can produce and/or receive raw PCM audio should do.

=head1 CONSTRUCTOR METHOD

    my $streamer = Audio::StreamGenerator->new( %options );

Creates a new StreamGenerator object and returns it.

=head1 OPTIONS

The following options can be specified:

    KEY                             DEFAULT     MANDATORY
    -----------                     -------     ---------
    out_fh                          -           yes
    get_new_source                  -           yes
    run_every_second                -           no
    normal_fade_seconds             5           no
    buffer_length_seconds           10          no
    skip_fade_seconds               3           no
    sample_rate                     44100       no
    channels_amount                 2           no
    max_vol_before_mix_fraction     0.75        no
    min_audible_vol_fraction        0.005       no
    debug                           0           no

=head2 out_fh

The outgoing file handle - this is where the generated signed 16-bit little-endian PCM audio stream is sent to.

Note that StreamGenerator has no notion of time - if you don't slow it down, it will process data as fast as it can - which is faster than your listeners are able to play the stream.
On Icecast, this will cause listeners to be disconnected because they are "too far behind".

This can be addressed by making sure that the out_fh process consumes the audio no faster than realtime.

If you are using ffmpeg, you can achieve this with its '-re' option.

Another possibility is to first pipe the data to a command like 'pv' to rate limit the data. An additional advantage of 'pv' is that it can also add a buffer between the StreamGenerator and the encoder, which can absorb any short delays that may occur when StreamGenerator is switching to a new track.

Example:

    pv -q -L 176400 -B 3528000 | ffmpeg ...

This will tell pv to be quiet (no output to STDERR), to allow a maximum throughput of 44100 samples per second * 2 bytes per sample * 2 channels = 176400 bytes per second, and keep a buffer of 176400 Bps * 20 seconds = 3528000 bytes

The out_fh command is also the place where you could insert a sound processing solution like the command line version of L<Stereo tool|https://www.stereotool.com/> - just pipe the audio first to that tool, and from there to your encoder.

=head2 get_new_source

Reference to a sub that will be called every time that a new source (audio file) is needed. Needs to return a readable filehandle that will output signed 16-bit little-endian PCM audio.

=head2 run_every_second

This sub will be run after each second of playback, with the StreamGenerator object as an argument. This can be used to do things like updating a UI with the current playing position - or to call the skip() method if we need to skip to the next source.

=head2 normal_fade_seconds

Amount of seconds that we want tracks to overlap. This is only the initial/max value - the mixing algorithm may decide to mix less seconds if the old track ends with loud samples.

=head2 buffer_length_seconds

Amount of seconds of the current track to keep in the buffer. Having this set to a higher value than normal_fade_seconds will ensure that there will be enough audio left to mix after removing silence at the end of the old track.

=head2 skip_fade_seconds

When 'skipping' to the next song using the skip() method (for example, after a user clicked a "next song" button on some web interface), we mix less seconds than normally, simply because mixing 5+ seconds in the middle of the old track sounds pretty bad. This value has to be lower than normal_fade_seconds.

=head2 sample_rate

The amount of samples per second (both incoming & outgoing), normally this is 44100 for standard CD-quality audio.

=head2 channels_amount

Amount of audio channels, this is normally 2 (stereo).

=head2 max_vol_before_mix_fraction

This tells StreamGenerator what the minimum volume of a 'loud' sample is. It is expressed as a fraction of the maximum volume.
When mixing 2 tracks, StreamGenerator needs to find out what the last loud sample of the old track is so that it can start the next song immediately after that.

=head2 min_audible_vol_fraction

Audio softer than this volume fraction at the end of a track (and within the buffer) will be skipped.

=head2 debug

Log debugging information. If the value is a code reference, the logs will be passed to that sub. Otherwise the value will be treated as a boolean. If true, logs will be printed to STDERR .

=head1 METHODS

=head2 stream

    $streamer->stream();

Start the actual audio stream.

=head2 get_streamer

    my $streamer_sub = $streamer->get_streamer($sec_per_call);

    while (1) {
        $streamer_sub->();
    }

Get an anonymous subroutine that will produce C<$sec_per_call> seconds of a stream when called.

C<$sec_per_call> is optional, and is by default C<1>.

Use this method instead of L<stream> if you want to have more control over the streaming process, for example, running the streamer inside an event loop:

    use Mojo::IOLoop;

    my $loop = Mojo::IOLoop->singleton;
    my $streamer_sub = $streamer->get_streamer(0.25);

    $loop->recurring(0.1 => $streamer_sub);
    $loop->start;

Note: event loop will be blocked for up to 0.25 seconds every time the timer is done.

=head2 skip

    $streamer->skip();

Skip to the next track without finishing the current one. This can be called from the "run_every_second" sub, for example after checking whether a 'skip' flag was set in a database, or whether a file exists.

=head2 get_elapsed_samples

    my $elapsed_samples = $streamer->get_elapsed_samples();
    print "$elapsed_samples played so far\r";

Get the amount of played samples in the current track - this can be called from the "run_every_second" sub.

=head2 get_elapsed_seconds

    my $elapsed_seconds = $streamer->get_elapsed_seconds();
    print "now at position $elapsed_seconds of the current track\r";

Get the amount of elapsed seconds in the current track - in other words the current position in the track. This equals to get_elapsed_samples/sample_rate .

