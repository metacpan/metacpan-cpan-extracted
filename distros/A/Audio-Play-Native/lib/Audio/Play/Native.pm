package Audio::Play::Native;

use 5.008001;
use strict;
use warnings;
use Carp  qw(croak);
use POSIX ();

our $VERSION = '0.01';

# Cached player binary path on Unix-like systems
our $CACHED_PLAYER;

sub _find_executable {
    my ($name) = @_;
    my $path_env = defined $ENV{PATH} ? $ENV{PATH} : '';
    for my $dir ( split /:/x, $path_env ) {
        my $path = "$dir/$name";
        return $path if -f $path && -x $path;
    }
    return;
}

sub _detect_linux_player {
    return $CACHED_PLAYER if defined $CACHED_PLAYER;

    # Preference order: PipeWire -> PulseAudio -> ALSA -> SoX -> FFplay
    for my $bin (qw(pw-play paplay aplay play ffplay)) {
        if ( my $path = _find_executable($bin) ) {
            $CACHED_PLAYER = $path;
            return $CACHED_PLAYER;
        }
    }
    return;
}

sub detected_backend {
    my ($class) = @_;
    my $backend;

    if ( $^O eq 'MSWin32' ) {
        my $win32_loaded = eval {
            require Win32::Sound;
            1;
        };
        if ($win32_loaded) {
            $backend = 'Win32::Sound';
        }
        else {
            $backend = 'PowerShell (Media.SoundPlayer)';
        }
    }
    elsif ( $^O eq 'darwin' ) {
        $backend = 'afplay';
    }
    else {
        my $player = _detect_linux_player();
        $backend = defined $player ? $player : 'none';
    }

    return $backend;
}

sub is_available {
    my ($class) = @_;
    $class = __PACKAGE__ unless defined $class;
    my $backend = $class->detected_backend;
    return ( defined $backend && $backend ne 'none' ) ? 1 : 0;
}

sub _play_windows {
    my ( $file, $async ) = @_;

    my $win32_ok = eval {
        require Win32::Sound;
        my $flags = $async ? 1 : 0;    # 1 = SND_ASYNC, 0 = SND_SYNC
        Win32::Sound::Play( $file, $flags );
    };

    return 1 if $win32_ok;

    # Fallback: Windows PowerShell Media.SoundPlayer
    my $method     = $async ? 'Play()' : 'PlaySync()';
    my $clean_path = $file;
    $clean_path =~ s/'/''/gx;
    my $cmd = sprintf( "(New-Object Media.SoundPlayer '%s').%s", $clean_path, $method );
    my $mode = $async ? 1 : 0;
    return system( $mode, 'powershell', '-NoProfile', '-Command', $cmd ) == 0;
}

sub _play_darwin {
    my ( $file, $async ) = @_;

    if ($async) {
        local $SIG{CHLD} = 'IGNORE';
        my $pid = fork();
        if ( defined $pid && $pid == 0 ) {
            open( STDIN,  '<', '/dev/null' ) or POSIX::_exit(1);
            open( STDOUT, '>', '/dev/null' ) or POSIX::_exit(1);
            open( STDERR, '>', '/dev/null' ) or POSIX::_exit(1);
            exec( 'afplay', $file ) or POSIX::_exit(1);
        }
        return $pid;
    }
    return system( 'afplay', $file ) == 0;
}

sub _play_unix {
    my ( $file, $async ) = @_;
    my $player = _detect_linux_player();
    return unless $player;

    if ($async) {
        local $SIG{CHLD} = 'IGNORE';
        my $pid = fork();
        if ( defined $pid && $pid == 0 ) {
            open( STDIN,  '<', '/dev/null' ) or POSIX::_exit(1);
            open( STDOUT, '>', '/dev/null' ) or POSIX::_exit(1);
            open( STDERR, '>', '/dev/null' ) or POSIX::_exit(1);

            if ( $player =~ m{/aplay$}x ) {
                exec( $player, '-q', $file ) or POSIX::_exit(1);
            }
            elsif ( $player =~ m{/ffplay$}x ) {
                exec( $player, '-nodisp', '-autoexit', '-loglevel', 'quiet', $file )
                  or POSIX::_exit(1);
            }
            else {
                exec( $player, $file ) or POSIX::_exit(1);
            }
        }
        return $pid;
    }

    if ( $player =~ m{/aplay$}x ) {
        return system( $player, '-q', $file ) == 0;
    }
    elsif ( $player =~ m{/ffplay$}x ) {
        return
          system( $player, '-nodisp', '-autoexit', '-loglevel', 'quiet', $file )
          == 0;
    }
    return system( $player, $file ) == 0;
}

sub play {
    my ( $class, $file, %opts ) = @_;

    croak "No audio file specified" unless defined $file;
    return                          unless -f $file && -r $file;

    my $async = exists $opts{async} ? $opts{async} : 1;

    if ( $^O eq 'MSWin32' ) {
        return _play_windows( $file, $async );
    }
    elsif ( $^O eq 'darwin' ) {
        return _play_darwin( $file, $async );
    }
    else {
        return _play_unix( $file, $async );
    }
}

sub generate_demo_wav {
    my ( $class, $filepath, %args ) = @_;

    my $duration_sec = defined $args{duration}  ? $args{duration}  : 0.35;
    my $freq         = defined $args{frequency} ? $args{frequency} : 587.33;
    my $type         = defined $args{type}      ? $args{type}      : 'ping';

    my $sample_rate = 44100;
    my $num_samples = int( $sample_rate * $duration_sec );
    my $data_size   = $num_samples * 2;                      # 16-bit mono
    my $file_size   = 36 + $data_size;

    my $header = pack(
        'A4VA4A4VvvVVvvA4V',
        'RIFF', $file_size, 'WAVE',
        'fmt ', 16,         1,      1, $sample_rate, $sample_rate * 2,
        2,      16,         'data', $data_size
    );

    my $pi     = 3.14159265358979323846;
    my $buffer = '';

    for my $i ( 0 .. $num_samples - 1 ) {
        my $t = $i / $sample_rate;
        my $sample;

        if ( $type eq 'explosion' ) {
            my $decay = exp( -6.0 * $t );
            my $noise = ( rand(2.0) - 1.0 );
            $sample = int( 28000 * $decay * $noise );
        }
        else {
            my $decay = exp( -8.0 * $t );
            $sample = int( 26000 * $decay * sin( 2 * $pi * $freq * $t ) );
        }

        $sample =  32767 if $sample > 32767;
        $sample = -32768 if $sample < -32768;

        # 16-bit signed little-endian PCM sample (Perl 5.8+ portable packing)
        $buffer .= pack( 'v', $sample & 0xFFFF );
    }

    open my $fh, '>:raw', $filepath or croak "Cannot write $filepath: $!";
    print $fh $header, $buffer;
    close $fh;

    return $filepath;
}

1;

__END__

=pod

=head1 NAME

Audio::Play::Native - Lightweight, cross-platform audio playback

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Audio::Play::Native;

    # Asynchronous non-blocking playback
    Audio::Play::Native->play('explosion.wav');

    # Synchronous blocking playback
    Audio::Play::Native->play('intro.wav', async => 0);

    # Query active backend
    print "Using backend: " . Audio::Play::Native->detected_backend . "\n";

=head1 DESCRIPTION

C<Audio::Play::Native> provides cross-platform audio playback for Perl. It does this by attempting to find and use available audio player tools to play the specified WAV file.

=head2 Linux

Will try to use PipeWire (C<pw-play>), PulseAudio (C<paplay>), ALSA (C<aplay>), SoX (C<play>), and FFplay (C<ffplay>).

=head2 Windows

Will try to use C<Win32::Sound> and PowerShell.

=head2 macOS

Will try to use C<afplay>.

=head1 AI

This module was developed with assistance from Gemini Flash 3.8.

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at affectivesilicon.com> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Matt Johnson.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

