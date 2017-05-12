use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 14;

use Audio::Scan;

# DSF64
{
    my $s = Audio::Scan->scan( _f('dff64.dff') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{audio_offset}, 130, 'Audio offset ok' );
    is( $info->{audio_size}, 40540, 'Audio size ok' );
    is( $info->{bits_per_sample}, 1, 'Bits/sample ok' );
    is( $info->{file_size}, 40734, 'File size ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{song_length_ms}, 57, 'Song length ok' );
    is( $info->{samplerate}, 2822400, 'Sample rate ok' );
}

# DSF128
{
    my $s = Audio::Scan->scan( _f('dff128.dff') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{audio_offset}, 130, 'Audio offset ok' );
    is( $info->{audio_size}, 48040, 'Audio size ok' );
    is( $info->{bits_per_sample}, 1, 'Bits/sample ok' );
    is( $info->{file_size}, 48234, 'File size ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{song_length_ms}, 34, 'Song length ok' );
    is( $info->{samplerate}, 5644800, 'Sample rate ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'dsdiff', shift );
}