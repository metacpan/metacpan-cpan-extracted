package Audio::StreamGenerator;

our $VERSION = 0.05;

use strict;
use warnings;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

my $logger = Log::Log4perl->get_logger('Audio::StreamGenerator');

sub new {
    my ( $class, %args ) = @_;

    my %defaults = (
        normal_fade_seconds         => 5,
        skip_fade_seconds           => 3,
        sample_rate                 => 44100,
        channels_amount             => 2,
        max_vol_before_mix_fraction => 0.75
    );

    my @mandatory_keys = qw (
        get_new_source
        out_fh
    );

    my @optional_keys = qw(
        run_every_second
    );

    foreach my $key (@mandatory_keys) {
        $logger->logcarp("value for $key is missing") if !defined( $args{$key} );
    }
    my %key_lookup = map { $_ => 1 } ( @mandatory_keys, @optional_keys );

    foreach my $key ( keys %args ) {
        $logger->logcarp("unknown argument '$key'")
            if !defined( $key_lookup{$key} );
    }

    my %self = ( %defaults, %args{ @mandatory_keys, @optional_keys } );

    bless \%self, $class;
}

sub stream {
    my $self = shift;

    $self->{source} = $self->_do_get_new_source();
    $self->{buffer} = [];
    $self->{skip}   = 0;

    my $short_clips_seen = 0;
    my $maxint           = 32767;

    my @channels;
    push @channels, $_ for 0 ... ( $self->{channels_amount} - 1 );

    while (1) {

        if ( eof( $self->{source} ) || $self->{skip} ) {

            if ( $self->{skip} ) {
                $logger->info('shortening buffer for skip...');
                pop @{ $self->{buffer} }
                    for 0 ... ( $self->{sample_rate} * ( $self->{normal_fade_seconds} - $self->{skip_fade_seconds} ) );
            }

            close( $self->{source} );
            my $old_elapsed_seconds = $self->{elapsed} / $self->{sample_rate};
            $self->{source} = $self->_do_get_new_source();

            $logger->info("old_elapsed_seconds: $old_elapsed_seconds");
            if ( $old_elapsed_seconds < ( $self->{normal_fade_seconds} * 2 ) ) {
                $short_clips_seen++;
                if ( $short_clips_seen >= 2 ) {
                    $logger->info('not mixing');
                    next;
                } else {
                    $logger->info(
                        "short, but mixing anyway because short_clips_seen is $short_clips_seen and old_elapsed_seconds is $old_elapsed_seconds"
                    );
                }
            } else {
                $short_clips_seen = 0;
                $logger->info('mixing');
            }

            my $index                  = 0;
            my $last_loud_sample_index = -1;
            my $threshold              = $maxint * $self->{max_vol_before_mix_fraction};
            my $max_old                = 0;
            foreach my $sample ( @{ $self->{buffer} } ) {
                foreach (@channels) {
                    my $single_sample = $sample->[$_];
                    $single_sample *= -1 if $single_sample < 0;
                    if ( $single_sample >= $threshold ) {
                        $last_loud_sample_index = $index;
                    }
                    if ( $single_sample > $max_old ) {
                        $max_old = $single_sample;
                    }
                }
                $index++;
            }

            $logger->info( "last loud sample index: $last_loud_sample_index of " . scalar( @{ $self->{buffer} } ) );
            $logger->info("loudest sample value: $max_old");

            my @new_buffer;
            while ( @new_buffer < @{ $self->{buffer} } ) {
                my $sample = $self->_get_sample();
                last if !defined($sample);
                push( @new_buffer, $sample );
            }

            my @max   = (0) x $self->{channels_amount};
            my $total = scalar( @{ $self->{buffer} } );
            $index = -1;
            foreach my $sample ( @{ $self->{buffer} } ) {
                $index++;
                my $togo = $total - $index;

                my $mod = $index % $self->{sample_rate};

                my $full_second;
                if ( !( $index % $self->{sample_rate} ) ) {
                    $full_second = $index / $self->{sample_rate};
                }

                if ( !$self->{skip} && $index <= $last_loud_sample_index ) {
                    if ( defined($full_second) ) {
                        $logger->info("skipping second $full_second...");
                    }
                    next;
                }

                if ( defined $full_second ) {
                    $logger->info("mixing second $full_second...");
                }

                if ( $self->{skip} ) {
                    my $fraction = $togo / $total;
                    foreach my $single_sample (@$sample) {
                        $single_sample *= $fraction;
                    }
                }

                if ( @new_buffer >= $togo ) {
                    my $newsample = shift @new_buffer;

                    for my $channel (@channels) {
                        $sample->[$channel] += $newsample->[$channel];
                    }
                }

                foreach my $channel (@channels) {
                    my $value = $sample->[$channel];
                    $value *= -1 if $value < 0;
                    if ( $value > $max[$channel] ) {
                        $max[$channel] = $value;
                    }
                }
            }

            push( @{ $self->{buffer} }, @new_buffer );

            my $channel = 0;

            foreach my $channel (@channels) {
                $logger->info("channel $channel needs volume adjustment")
                    if ( $max[$channel] > $maxint );
            }

            foreach my $sample ( @{ $self->{buffer} } ) {
                for my $channel (@channels) {
                    if ( $max[$channel] > $maxint ) {
                        $sample->[$channel] =
                            ( $sample->[$channel] / $max[$channel] ) * $maxint;
                    }
                }
            }

            $self->{skip} = 0;

        }

        while ( @{ $self->{buffer} } < ( $self->{normal_fade_seconds} * $self->{sample_rate} ) ) {
            my $sample = $self->_get_sample();
            last if !defined($sample);
            push( @{ $self->{buffer} }, $sample );
        }

        $self->_send_one_sample();

        if ( !( $self->{elapsed} % $self->{sample_rate} )
            && defined( $self->{run_every_second} ) )
        {
            $self->{run_every_second}($self);
        }

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

sub _send_one_sample {
    my $self   = shift;
    my $sample = shift @{ $self->{buffer} };
    my $fh     = $self->{out_fh};
    print $fh map { pack 's*', $_ } @$sample;
}

sub _get_sample {
    my $self = shift;
    return undef if eof( $self->{source} );
    my $data;
    read( $self->{source}, $data, $self->{channels_amount} * 2 );
    $self->{elapsed}++;

    if ( length($data) == ( $self->{channels_amount} * 2 ) ) {
        my @sample;
        while ( length($data) ) {
            my $bytes_this_sample = substr( $data, 0, $self->{channels_amount} * 2, '' );
            push( @sample, unpack 's*', $bytes_this_sample );
        }
        return \@sample;
    } else {
        my @sample = (0) x ( $self->{channels_amount} * 2 );
        return \@sample;
    }
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
    skip_fade_seconds               3           no
    sample_rate                     44100       no
    channels_amount                 2           no
    max_vol_before_mix_fraction     0.75        no

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
    
=head2 skip_fade_seconds

When 'skipping' to the next song using the skip() method (for example, after a user clicked a "next song" button on some web interface), we mix less seconds than normally, simply because mixing 5+ seconds in the middle of the old track sounds pretty bad. This value has to be lower than normal_fade_seconds. 
    
=head2 sample_rate

The amount of samples per second (both incoming & outgoing), normally this is 44100 for standard CD-quality audio. 
    
=head2 channels_amount

Amount of audio channels, this is normally 2 (stereo). 

=head2 max_vol_before_mix_fraction

This tells StreamGenerator what the minimum volume of a 'loud' sample is. It is expressed as a fraction of the maximum volume. 
When mixing 2 tracks, StreamGenerator needs to find out what the last loud sample of the old track is so that it can start the next song immediately after that. 

=head1 METHODS

=head2 stream

    $streamer->stream();

Start the actual audio stream.

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
