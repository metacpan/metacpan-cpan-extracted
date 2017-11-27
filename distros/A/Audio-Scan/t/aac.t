use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 39;
use Test::Warn;

use Audio::Scan;

# TODO: DLNA profile tests
#   AAC_ADTS_320
#   HEAAC_L2_ADTS
#   HEAAC_L3_ADTS
#   AAC_ADTS
#   HEAAC_MULT5_ADTS
#   AAC_MULT5_ADTS
#   Non-compliant file

# Failing profiles:
#   O-AAC_ADTS_192-stereo-22.05kHz-45.adts (detects as HEAAC due to low samplerate)
#   O-AAC_ADTS_192-stereo-48kHz-141.adts (detects as AAC_ADTS_320 because bitrate is too high)

# Mono ADTS file
{
    my $s = Audio::Scan->scan( _f('mono.aac') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'Audio offset ok' );
    is( $info->{audio_size}, 2053, 'Audio size ok' );
    is( $info->{bitrate}, 37000, 'Bitrate ok' );
    is( $info->{channels}, 1, 'Channels ok' );
    is( $info->{file_size}, 2053, 'File size ok' );
    is( $info->{profile}, 'LC', 'Profile ok' );
    is( $info->{samplerate}, 44100, 'Samplerate ok' );
    is( $info->{song_length_ms}, 441, 'Duration ok' );
    is( $info->{dlna_profile}, 'AAC_ADTS_192', 'DLNA profile AAC_ADTS_192 ok' );
}

# Stereo ADTS file
{
    my $s = Audio::Scan->scan( _f('stereo.aac') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'Stereo ADTS audio offset ok' );
    is( $info->{bitrate}, 59000, 'Stereo ADTS bitrate ok' );
    is( $info->{channels}, 2, 'Stereo ADTS channels ok' );
    is( $info->{profile}, 'LC', 'Stereo ADTS profile ok' );
    is( $info->{samplerate}, 44100, 'Stereo ADTS samplerate ok' );
    is( $info->{song_length_ms}, 1369, 'Stereo ADTS duration ok' );
}

# ADTS with ID3v2 tags
{
    my $s = Audio::Scan->scan( _f('id3v2.aac'), { md5_size => 4096 } );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 2182, 'ID3v2 audio offset ok' );
    is( $info->{audio_size}, 2602, 'ID3v2 audio_size ok' );
    is( $info->{audio_md5}, 'f84210edefebcd92792fd1b3d21860d5', 'ID3v2 audio_md5 ok' );
    is( $info->{bitrate}, 149000, 'ID3v2 bitrate ok' );
    is( $info->{channels}, 2, 'ID3v2 channels ok' );
    is( $info->{profile}, 'LC', 'ID3v2 profile ok' );
    is( $info->{samplerate}, 44100, 'ID3v2 samplerate ok' );
    is( $info->{song_length_ms}, 139, 'ID3v2 duration ok' );
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3v2 version ok' );

    is( $tags->{TPE1}, 'Calibration Level', 'ID3v2 TPE1 ok' );
    is( $tags->{TENC}, 'ORBAN', 'ID3v2 TENC ok' );
    is( $tags->{TIT2}, '1kHz -20dBfs', 'ID3v2 TIT2 ok' );
}

# ADTS with leading junk (from a radio stream)
{
    my $s;
    warning_like { $s = Audio::Scan->scan( _f('leading-junk.aac') ); }
        [ qr/Unable to read at least/ ],
        'Leading junk warning ok';

    my $info = $s->{info};

    is( $info->{audio_offset}, 638, 'Leading junk offset ok' );
    is( $info->{bitrate}, 128000, 'Leading junk bitrate ok' );
    is( $info->{channels}, 2, 'Leading junk channels ok' );
    is( $info->{profile}, 'LC', 'Leading junk profile ok' );
    is( $info->{samplerate}, 44100, 'Leading junk samplerate ok' );
    is( $info->{dlna_profile}, 'HEAAC_L2_ADTS_320', 'Leading junk DLNA profile HEAAC_L2_ADTS_320 ok' );
}

# Bug 16874, truncated with a partial header
{
    my $s = Audio::Scan->scan( _f('truncated.aac') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 26, 'Truncated offset ok' );
    is( $info->{bitrate}, 52000, 'Truncated bitrate ok' );
    is( $info->{channels}, 2, 'Truncated channels ok' );
    is( $info->{profile}, 'LC', 'Truncated profile ok' );
    is( $info->{samplerate}, 44100, 'Truncated samplerate ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'aac', shift );
}
