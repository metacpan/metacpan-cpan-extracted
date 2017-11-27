use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 79;

use Audio::Scan;

# Silence file with APEv2 tag
{
    my $s = Audio::Scan->scan( _f('silence-44-s.wv'), { md5_size => 4096 } );
    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{ape_version}, 'APEv2', 'APE version ok' );
    is( $info->{audio_offset}, 0, 'audio_offset ok' );
    is( $info->{audio_size}, 34782, 'audio_size ok' );
    is( $info->{audio_md5}, '13dbb42069ac266a4d45f109c67c072f', 'audio_md5 ok' );
    is( $info->{bitrate}, 76323, 'bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'bits_per_sample ok' );
    is( $info->{channels}, 2, 'channels ok' );
    is( $info->{encoder_version}, 0x403, 'version ok' );
    is( $info->{file_size}, 35147, 'file_size ok' );
    is( $info->{lossless}, 1, 'lossless ok' );
    is( $info->{samplerate}, 44100, 'samplerate ok' );
    is( $info->{song_length_ms}, 3684, 'song_length_ms ok' );
    is( $info->{total_samples}, 162496, 'total_samples ok' );

    is( $tags->{DATE}, 2004, 'DATE ok' );
    is( $tags->{GENRE}, 'Silence', 'GENRE ok' );
    is( $tags->{TITLE}, 'Silence', 'TITLE ok' );
}

# Self-extracting file (why?!)
{
    my $s = Audio::Scan->scan_info( _f('win-executable.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 30720, 'EXE audio_offset ok' );
    is( $info->{song_length_ms}, 29507, 'EXE song_length_ms ok' );
}

# Hybrid (lossy) file
{
    my $s = Audio::Scan->scan_info( _f('hybrid.wv') );
    my $info = $s->{info};

    is( $info->{bitrate}, 199913, 'hybrid bitrate ok' );
    is( $info->{channels}, 2, 'hybrid channels ok' );
    is( $info->{hybrid}, 1, 'hybrid hybrid flag ok' );
    is( $info->{samplerate}, 44100, 'hybrid samplerate ok' );
    is( $info->{song_length_ms}, 1019, 'hybrid song_length_ms ok' );
}

# 24-bit file
{
    my $s = Audio::Scan->scan_info( _f('24-bit.wv') );
    my $info = $s->{info};

    is( $info->{bits_per_sample}, 24, '24-bit bits_per_sample ok' );
    is( $info->{channels}, 2, '24-bit channels ok' );
    is( $info->{samplerate}, 88200, '24-bit samplerate ok' );
    is( $info->{song_length_ms}, 147101, '24-bit song_length_ms ok' );
    is( $info->{total_samples}, 12974320, '24-bit total_samples ok' );
}

# File with initial block containing 0 block_samples (bug 8601)
{
    my $s = Audio::Scan->scan_info( _f('zero-first-block.wv') );
    my $info = $s->{info};

    is( $info->{bits_per_sample}, 16, 'Zero first block bits_per_sample ok' );
    is( $info->{channels}, 2, 'Zero first block channels ok' );
    is( $info->{samplerate}, 44100, 'Zero first block samplerate ok' );
    is( $info->{song_length_ms}, 36506, 'Zero first block song_length_ms ok' );
    is( $info->{total_samples}, 1609944, 'Zero first block total_samples ok' );
}

# v3 file
{
    my $s = Audio::Scan->scan_info( _f('v3.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'v3 audio_offset ok' );
    is( $info->{bitrate}, 4, 'v3 bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'v3 bits_per_sample ok' );
    is( $info->{channels}, 2, 'v3 channels ok' );
    is( $info->{encoder_version}, 3, 'v3 encoder_version ok' );
    is( $info->{file_size}, 176, 'v3 file_size ok' );
    is( $info->{samplerate}, 44100, 'v3 samplerate ok' );
    is( $info->{song_length_ms}, 329280, 'v3 song_length_ms ok' );
    is( $info->{total_samples}, 14521248, 'v3 total_samples ok' );
}

# v2 file
{
    my $s = Audio::Scan->scan_info( _f('v2.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'v2 audio_offset ok' );
    is( $info->{bitrate}, 80, 'v2 bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'v2 bits_per_sample ok' );
    is( $info->{channels}, 2, 'v2 channels ok' );
    is( $info->{encoder_version}, 2, 'v2 encoder_version ok' );
    is( $info->{file_size}, 368, 'v2 file_size ok' );
    is( $info->{samplerate}, 44100, 'v2 samplerate ok' );
    is( $info->{song_length_ms}, 36506, 'v2 song_length_ms ok' );
    is( $info->{total_samples}, 1609944, 'v2 total_samples ok' );
}

# Custom samplerate
{
    my $s = Audio::Scan->scan_info( _f('custom-samplerate.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'custom-samplerate audio_offset ok' );
    is( $info->{bitrate}, 149, 'custom-samplerate bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'custom-samplerate bits_per_sample ok' );
    is( $info->{channels}, 2, 'custom-samplerate channels ok' );
    is( $info->{encoder_version}, 0x407, 'custom-samplerate encoder_version ok' );
    is( $info->{file_size}, 560, 'custom-samplerate file_size ok' );
    is( $info->{samplerate}, 40000, 'custom-samplerate samplerate ok' );
    is( $info->{song_length_ms}, 30000, 'custom-samplerate song_length_ms ok' );
    is( $info->{total_samples}, 1200001, 'custom-samplerate total_samples ok' );
}

# Multi-channel file
{
    my $s = Audio::Scan->scan_info( _f('6channel.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 0, '6channel audio_offset ok' );
    is( $info->{bitrate}, 265, '6channel bitrate ok' );
    is( $info->{bits_per_sample}, 16, '6channel bits_per_sample ok' );
    is( $info->{channels}, 6, '6channel channels ok' );
    is( $info->{encoder_version}, 0x406, '6channel encoder_version ok' );
    is( $info->{file_size}, 1024, '6channel file_size ok' );
    is( $info->{samplerate}, 44100, '6channel samplerate ok' );
    is( $info->{song_length_ms}, 30906, '6channel song_length_ms ok' );
    is( $info->{total_samples}, 1362998, '6channel total_samples ok' );
}

# v5 DSD file
{
    my $s = Audio::Scan->scan_info( _f('v5-dsd.wv') );
    my $info = $s->{info};

    is( $info->{audio_offset}, 0, 'v5-dsd audio_offset ok' );
    is( $info->{audio_size}, 690, 'v5-dsd audio_size ok' );
    is( $info->{bitrate}, 5, 'v5-dsd bitrate ok' );
    is( $info->{bits_per_sample}, 1, 'v5-dsd bits_per_sample ok' );
    is( $info->{channels}, 2, 'v5-dsd channels ok' );
    is( $info->{encoder_version}, 0x410, 'v5-dsd encoder_version ok' );
    is( $info->{file_size}, 690, 'v5-dsd file_size ok' );
    is( $info->{samplerate}, 2822400, 'v5-dsd samplerate ok' );
    is( $info->{song_length_ms}, 1044491, 'v5-dsd song_length_ms ok' );
    is( $info->{total_samples}, 2947973120, 'v5-dsd total_samples ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'wavpack', shift );
}
