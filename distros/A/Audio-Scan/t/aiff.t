use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 31;

use Audio::Scan;

# TODO: LPCM_low profile test

# AIFF file with ID3 tags (tagged by iTunes)
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

    my $s = Audio::Scan->scan( _f('aiff-id3.aif'), { md5_size => 4096 } );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 54, 'Audio offset ok' );
    is( $info->{audio_size}, 1904, 'Audio size ok' );
    is( $info->{audio_md5}, '31f0818c53cc2bb521cf58960cea9821', 'Audio MD5 ok' );
    is( $info->{bitrate}, 1411200, 'Bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'Bits/sample ok' );
    is( $info->{block_align}, 4, 'Block align ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{file_size}, 14932, 'File size ok' );
    is( $info->{samplerate}, 44100, 'Sample rate ok' );
    is( $info->{song_length_ms}, 10, 'Song length ok' );
    is( $info->{id3_version}, 'ID3v2.2.0', 'ID3 version ok' );
    is( $info->{dlna_profile}, 'LPCM', 'DLNA profile ok' );

    is( $tags->{TALB}, '...And So It Goes', 'TALB ok' );
    is( $tags->{TCON}, 'Electronica/Dance', 'TCON ok' );
    is( $tags->{TDRC}, 2008, 'TDRC ok' );
    is( $tags->{TIT2}, 'Dark Roads', 'TIT2 ok' );
    is( $tags->{TPE1}, 'Kaya Project', 'TPE1 ok' );

    # Bug 17392, make sure artwork offset is correct when ID3 tag is not at the front of the file
    is( $tags->{APIC}->[0], 'JPG', 'APIC JPG ok' );
    is( $tags->{APIC}->[3], 2277, 'APIC length ok' );
    is( $tags->{APIC}->[4], 2414, 'APIC offset ok' );
}

# AIFF file with ID3 tags with a bad chunksize
{
    my $s = Audio::Scan->scan( _f('aiff-id3-bad-chunksize.aif') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{id3_version}, 'ID3v2.2.0', 'ID3 version ok' );

    is( $tags->{TPE1}, 'Kaya Project', 'TPE1 ok' );
}

# 32-bit AIFF with PEAK info
{
    my $s = Audio::Scan->scan( _f('aiff32.aiff') );

    my $info = $s->{info};

    is( $info->{bitrate}, 2822400, '32-bit AIFF bitrate ok' );
    is( $info->{bits_per_sample}, 32, '32-bit AIFF bits/sample ok' );
    is( $info->{block_align}, 8, '32-bit AIFF block align ok' );
    is( ref $info->{peak}, 'ARRAY', '32-bit AIFF PEAK ok' );
    is( $info->{peak}->[0]->{position}, 284, '32-bit AIFF Peak 1 ok' );
    is( $info->{peak}->[1]->{position}, 47, '32-bit AIFF Peak 2 ok' );
    like( $info->{peak}->[0]->{value}, qr/^0.477/, '32-bit AIFF Peak 1 value ok' );
    like( $info->{peak}->[1]->{value}, qr/^0.476/, '32-bit AIFF Peak 2 value ok' );
    ok( !exists $info->{dlna_profile}, '32-bit AIFF no DLNA profile ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'aiff', shift );
}
