use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 36;

use Audio::Scan;

# SV7 file with APEv2 tags
{
    my $s = Audio::Scan->scan( _f('apev2.mpc'), { md5_size => 51581 } );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 24, 'Audio offset ok' );
    is( $info->{audio_size}, 51581, 'Audio size ok' );
    is( $info->{audio_md5}, '62fc45d1283233d8f03c199a5dece1f9', 'Audio MD5 ok' );
    is( $info->{bitrate}, 692, 'Bitrate ok' );
    is( $info->{encoder}, 'Buschmann 1.7.0...9, Klemm 0.90...1.05', 'encoder ok' );
    is( $info->{file_size}, 51782, 'File size ok' );
    is( $info->{profile}, 'Extreme (q=6)', 'Profile ok' );
    is( $info->{samplerate}, 44100, 'Sample rate ok' );
    is( $info->{song_length_ms}, 598138, 'Song length ok' );
    is( $info->{channels}, 2, 'Channels version ok' );
    is( $info->{gapless}, 1, 'Gapless ok' );
    is( $info->{track_gain}, '-2.89 dB', 'Track gain ok' );
    is( $info->{album_gain}, '-5.63 dB', 'Album gain ok' );

    is( $tags->{ALBUM}, 'Special Cases', 'Album ok' );
    is( $tags->{ARTIST}, 'Massive Attack', 'Artist ok' );
    is( $tags->{TITLE}, 'Special Cases [Akufen remix]', 'Title ok' );
    is( $tags->{TRACK}, 2, 'Track ok' );
}

# SV8 file, no tags
{
    my $s = Audio::Scan->scan( _f('sv8.mpc') );

    my $info = $s->{info};

    is( $info->{audio_offset}, 24, 'SV8 offset ok' );
    is( $info->{bitrate}, 19, 'SV8 bitrate ok' );
    is( $info->{encoder}, '--Stable-- 1.30.0', 'SV8 encoder ok' );
    is( $info->{file_size}, 208, 'SV8 file size ok' );
    is( $info->{profile}, 'Standard (q=5)', 'SV8 profile ok' );
    is( $info->{samplerate}, 44100, 'SV8 samplerate ok' );
    is( $info->{song_length_ms}, 75626, 'SV8 song length ok' );
    is( $info->{channels}, 2, 'SV8 channels ok' );
    is( $info->{gapless}, 1, 'SV8 gapless ok' );
    is( $info->{track_gain}, '4.16 dB', 'SV8 track gain ok' );
    is( $info->{album_gain}, '4.16 dB', 'SV8 album gain ok' );
}

# File with binary cover in APEv2 tag, and no header
{
    my $s = Audio::Scan->scan( _f('apev2-cover.mpc') );

    my $tags = $s->{tags};
    is( $tags->{ALBUM}, 'Cover Art Test', 'APEv2 with cover album ok' );
    is( $tags->{ARTIST}, 'Kraftwerk', 'APEv2 with cover artist ok' );
    is( length( $tags->{'COVER ART (FRONT)'} ), 1761, 'APEv2 with cover binary cover ok' );
    is( unpack( 'H*', substr( $tags->{'COVER ART (FRONT)'}, 0, 4 ) ), 'ffd8ffe0', 'APEv2 with cover JPEG picture data ok ');
}

# Test cover handling with no artwork var
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

    my $s = Audio::Scan->scan( _f('apev2-cover.mpc') );

    my $tags = $s->{tags};
    is( $tags->{ALBUM}, 'Cover Art Test', 'APEv2 AUDIO_SCAN_NO_ARTWORK album ok' );
    is( $tags->{ARTIST}, 'Kraftwerk', 'APEv2 AUDIO_SCAN_NO_ARTWORK artist ok' );
    is( $tags->{'COVER ART (FRONT)'}, 1761, 'APEv2 AUDIO_SCAN_NO_ARTWORK cover length ok' );
    is( $tags->{'COVER ART (FRONT)_offset'}, 68925, 'APEv2 AUDIO_SCAN_NO_ARTWORK cover offset ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'musepack', shift );
}
