use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 22;

use Audio::Scan;

# DSF64
{
    my $s = Audio::Scan->scan( _f('dsf64.dsf') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{audio_offset}, 92, 'Audio offset ok' );
    is( $info->{audio_size}, 40960, 'Audio size ok' );
    is( $info->{bits_per_sample}, 1, 'Bits/sample ok' );
    is( $info->{file_size}, 41158, 'File size ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{song_length_ms}, 57, 'Song length ok' );
    is( $info->{samplerate}, 2822400, 'Sample rate ok' );
    is( $info->{block_size_per_channel}, 4096, 'Block align ok' );

    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3 version ok' );
    
    is( $tags->{TDRC}, '2013-12-29T19:40', 'TALB ok' );
    is( $tags->{TSSE}, 'KORG AudioGate ver.2.3.3 (Windows 7)', 'TCON ok' );
}

# DSF128
{
    my $s = Audio::Scan->scan( _f('dsf128.dsf') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{audio_offset}, 92, 'Audio offset ok' );
    is( $info->{audio_size}, 49152, 'Audio size ok' );
    is( $info->{bits_per_sample}, 1, 'Bits/sample ok' );
    is( $info->{file_size}, 49350, 'File size ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{song_length_ms}, 34, 'Song length ok' );
    is( $info->{samplerate}, 5644800, 'Sample rate ok' );
    is( $info->{block_size_per_channel}, 4096, 'Block align ok' );

    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3 version ok' );
    
    is( $tags->{TDRC}, '2013-12-29T19:40', 'TALB ok' );
    is( $tags->{TSSE}, 'KORG AudioGate ver.2.3.3 (Windows 7)', 'TCON ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'dsf', shift );
}