use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 58;

use Audio::Scan;

# TODO: LPCM_low profile test

# WAV file with ID3 tags
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

    my $s = Audio::Scan->scan( _f('id3.wav'), { md5_size => 4096 } );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 44, 'Audio offset ok' );
    is( $info->{audio_size}, 1904, 'Audio size ok' );
    is( $info->{audio_md5}, 'f69093529247ffd1dfaa5b7c66a19377', 'Audio MD5 ok' );
    is( $info->{bitrate}, 1411200, 'Bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'Bits/sample ok' );
    is( $info->{block_align}, 4, 'Block align ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{file_size}, 4240, 'File size ok' );
    is( $info->{format}, 1, 'Format ok' );
    is( $info->{samplerate}, 44100, 'Sample rate ok' );
    is( $info->{song_length_ms}, 10, 'Song length ok' );
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3 version ok' );
    is( $info->{dlna_profile}, 'LPCM', 'DLNA profile ok' );

    is( ref $tags->{COMM}, 'ARRAY', 'COMM ok' );
    is( $tags->{TALB}, 'WAV Album', 'TALB ok' );
    is( $tags->{TCON}, 'Alternative', 'TCON ok' );
    is( $tags->{TDRC}, 2009, 'TDRC ok' );
    is( $tags->{TIT2}, 'WAV Title', 'TIT2 ok' );
    is( $tags->{TPE1}, 'WAV Artist', 'TPE1 ok' );
    is( $tags->{TPOS}, 1, 'TPOS ok' );
    is( $tags->{TRCK}, 5, 'TRCK ok' );

    # Bug 17392, make sure artwork offset is correct when ID3 tag is not at the front of the file
    is( ref $tags->{APIC}, 'ARRAY', 'APIC ok' );
    is( $tags->{APIC}->[0], 'image/jpg', 'APIC type ok' );
    is( $tags->{APIC}->[3], 2103, 'APIC length ok' );
    is( $tags->{APIC}->[4], 2137, 'APIC offset ok' );
}

# 32-bit WAV with PEAK info
{
    my $s = Audio::Scan->scan( _f('wav32.wav') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 88, '32-bit WAV audio offset ok' );
    is( $info->{audio_size}, 3808, '32-bit WAV audio size ok' );
    is( $info->{bitrate}, 2822400, '32-bit WAV bitrate ok' );
    is( $info->{bits_per_sample}, 32, '32-bit WAV bits/sample ok' );
    is( $info->{block_align}, 8, '32-bit WAV block align ok' );
    is( ref $info->{peak}, 'ARRAY', '32-bit WAV PEAK ok' );
    is( $info->{peak}->[0]->{position}, 284, '32-bit WAV Peak 1 ok' );
    is( $info->{peak}->[1]->{position}, 47, '32-bit WAV Peak 2 ok' );
    like( $info->{peak}->[0]->{value}, qr/^0.477/, '32-bit WAV Peak 1 value ok' );
    like( $info->{peak}->[1]->{value}, qr/^0.476/, '32-bit WAV Peak 2 value ok' );
    ok( !exists $info->{dlna_profile}, '32-bit WAV no DLNA profile ok' );
}

# MP3 in WAV
{
    my $s = Audio::Scan->scan( _f('8kmp38.wav') );

    my $info = $s->{info};

    is( $info->{bitrate}, 8000, 'MP3 WAV bitrate ok' );
    is( $info->{format}, 85, 'MP3 WAV format ok' );
    is( $info->{samplerate}, 8000, 'MP3 WAV samplerate ok' );
    is( $info->{song_length_ms}, 13811, 'MP3 WAV length ok' );
}

# Wav with INFO tags and wrong chunk size in header
{
    my $s = Audio::Scan->scan( _f('wav32-info-badchunk.wav') );

    my $tags = $s->{tags};

    is( $tags->{IART}, 'They Might Be Giants', 'IART ok' );
    is( $tags->{ICRD}, 2005, 'ICRD ok' );
    is( $tags->{IGNR}, 'Soundtrack', 'IGNR ok' );
    is( $tags->{INAM}, 'Here Come The ABCs', 'INAM ok' );
    is( $tags->{IPRD}, 'Here Come The Abcs With Tmbg - Original Songs About The Alphabet', 'IPRD ok' );
}

# Bug 14946, WAV file with INFO tags with trailing nulls
{
    my $s = Audio::Scan->scan( _f('wav32-info-nulls.wav') );

    my $tags = $s->{tags};

    is( $tags->{IART}, 'Archies, The', 'INFO nulls IART ok' );
    is( $tags->{ICMT}, 'Gift From Uncle Roddy', 'INFO nulls ICMT ok' );
    is( $tags->{ICRD}, 1997, 'INFO nulls ICRD ok' );
    is( $tags->{IGNR}, 'Pop', 'INFO nulls IGNR ok' );
    is( $tags->{INAM}, 'Tester Bang Shang A Lang', 'INFO nulls INAM ok' );
    is( $tags->{IPRD}, 'When I Was Young', 'INFO nulls IPRD ok' );
}

# Bug 14462, WAV file with 18-byte fmt chunk
{
    my $s = Audio::Scan->scan( _f('bug14462-wav-fmt.wav') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 58, '18-byte fmt audio offset ok' );
    is( $info->{song_length_ms}, 7418, '18-byte fmt duration ok' );
}

# Bug 14462, WAV file with bad data size
{
    my $s = Audio::Scan->scan( _f('bug14462-wav-bad-data-size.wav') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 44, 'bad data size audio offset ok' );
    is( $info->{song_length_ms}, 2977, 'bad data size duration ok' );
}

# GH #2, bad duration calculated for files where the 'fact' chunk num_samples value is used
{
    my $s = Audio::Scan->scan( _f('gh2-wav32-bad-duration.wav') );

    my $info = $s->{info};

    is( $info->{bits_per_sample}, 32, 'GH#2, 32/384 bps ok' );
    is( $info->{samplerate}, 384000, 'GH#2, 32/384 samplerate ok' );
    is( $info->{song_length_ms}, 20000, 'GH#2, song_length_ms ok for 32/384 file with a high number of samples' );
}

sub _f {
    return catfile( $FindBin::Bin, 'wav', shift );
}
