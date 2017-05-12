use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 389;
use Test::Warn;

use Audio::Scan;

my $HAS_ENCODE;
my $pate;
my $raks;
eval {
    require Encode;
    $pate = Encode::decode_utf8("pâté");
    $raks = Encode::decode_utf8("räksmörgås");
    $HAS_ENCODE = 1;
};

## Test file info on non-tagged files

# MPEG1, Layer 2, 192k / 44.1kHz
{
    my $s = Audio::Scan->scan( _f('no-tags-mp1l2.mp3'), { md5_size => 4096 } );
    
    my $info = $s->{info};
    
    is( $info->{audio_md5}, 'af946979d80b4503a618e4056be0f3e0', 'MPEG1, Layer 2 audio MD5 ok' );
    is( $info->{layer}, 2, 'MPEG1, Layer 2 ok' );
    is( $info->{bitrate}, 192000, 'MPEG1, Layer 2 bitrate ok' );
    is( $info->{file_size}, 82756, 'MPEG1, Layer 2 file size ok' );
    is( $info->{samplerate}, 44100, 'MPEG1, Layer 2 samplerate ok' );
    like( $info->{jenkins_hash}, qr/^\d+$/, 'Jenkins hash ok' );
}

# MPEG2, Layer 2, 96k / 16khz mono
{
    my $s = Audio::Scan->scan( _f('no-tags-mp1l2-mono.mp3'), { md5_size => 32, md5_offset => 57936 } );
    
    my $info = $s->{info};
    
    is( $info->{audio_md5}, '65a9c980ab1f99d467777d2f1d83ed7b', 'MPEG2, Layer 2 audio MD5 using md5_offset ok' );
    is( $info->{layer}, 2, 'MPEG2, Layer 2 ok' );
    is( $info->{bitrate}, 96000, 'MPEG2, Layer 2 bitrate ok' );
    is( $info->{samplerate}, 16000, 'MPEG2, Layer 2 samplerate ok' );
    is( $info->{stereo}, 0, 'MPEG2, Layer 2 mono ok' );
}

# MPEG1, Layer 3, 32k / 32kHz
{
    my $s = Audio::Scan->scan( _f('no-tags-mp1l3.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 32000, 'MPEG1, Layer 3 bitrate ok' );
    is( $info->{samplerate}, 32000, 'MPEG1, Layer 3 samplerate ok' );
    is( $info->{dlna_profile}, 'MP3', 'MPEG1, Layer 3 DLNA profile MP3 ok' );
}

# MPEG2, Layer 3, 8k / 22.05kHz
{
    my $s = Audio::Scan->scan( _f('no-tags-mp2l3.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 8000, 'MPEG2, Layer 3 bitrate ok' );
    is( $info->{samplerate}, 22050, 'MPEG2, Layer 3 samplerate ok' );
    is( $info->{dlna_profile}, 'MP3X', 'MPEG2, Layer 3 DLNA profile MP3X ok' );
}

# MPEG2.5, Layer 3, 8k / 8kHz
{
    my $s = Audio::Scan->scan( _f('no-tags-mp2.5l3.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 8000, 'MPEG2.5, Layer 3 bitrate ok' );
    is( $info->{samplerate}, 8000, 'MPEG2.5, Layer 3 samplerate ok' );
    ok( !exists $info->{dlna_profile}, 'MPEG2.5, Layer 3 no DLNA profile ok' );
}

# MPEG1, Layer 3, ~40k / 32kHz VBR
{
    my $s = Audio::Scan->scan( _f('no-tags-mp1l3-vbr.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 40000, 'MPEG1, Layer 3 VBR bitrate ok' );
    is( $info->{samplerate}, 32000, 'MPEG1, Layer 3 VBR samplerate ok' );
    
    # Xing header
    is( $info->{xing_bytes}, $info->{audio_size}, 'Xing bytes field ok' );
    is( $info->{xing_frames}, 30, 'Xing frames field ok' );
    is( $info->{xing_quality}, 57, 'Xing quality field ok' );

    # LAME header
    is( $info->{lame_encoder_delay}, 576, 'LAME encoder delay ok' );
    is( $info->{lame_encoder_padding}, 1191, 'LAME encoder padding ok' );
    is( $info->{lame_vbr_method}, 'Average Bitrate', 'LAME VBR method ok' );
    is( $info->{vbr}, 1, 'LAME VBR flag ok' );
    is( $info->{lame_preset}, 'ABR 40', 'LAME preset ok' );
    is( $info->{lame_replay_gain_radio}, '-4.6 dB', 'LAME ReplayGain ok' );
    is( $info->{song_length_ms}, 1024, 'LAME VBR song_length_ms ok' );
}

# MPEG2, Layer 3, 320k / 44.1kHz CBR with LAME Info tag
{
    my $s = Audio::Scan->scan( _f('no-tags-mp1l3-cbr320.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 320000, 'CBR file bitrate ok' );
    is( $info->{samplerate}, 44100, 'CBR file samplerate ok' );
    is( $info->{vbr}, undef, 'CBR file does not have VBR flag' );
    is( $info->{lame_encoder_version}, 'LAME3.97 ', 'CBR file LAME Info tag version ok' );
    is( $info->{song_length_ms}, 1044, 'CBR file song_length_ms ok' );
}

# Non-Xing/LAME VBR file to test average bitrate calculation
{
	my $s = Audio::Scan->scan( _f('no-tags-no-xing-vbr.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 215000, 'Non-Xing VBR average bitrate calc ok' );
    is( $info->{song_length_ms}, 4974, 'Non-Xing VBR song_length_ms ok' );
}

# File with no audio frames, test is rejected properly
{
    my $s;
    warning_like { $s = Audio::Scan->scan_info( _f('v2.3-no-audio-frames.mp3') ); }
        [ qr/Unable to find any MP3 frames in file/ ],
        'File with no audio frames ok';
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, undef, 'File with no audio frames has undef bitrate ok' );
}

# MPEG1 Xing mono file to test xing_offset works properly
{
    my $s = Audio::Scan->scan_info( _f('no-tags-mp1l3-mono.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{stereo}, 0, 'MPEG1 Xing mono file ok' );
    is( $info->{xing_frames}, 42, 'MPEG1 Xing mono frames ok' );    
}

# MPEG2 Xing mono file to test xing_offset
{
    my $s = Audio::Scan->scan_info( _f('no-tags-mp2l3-mono.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{stereo}, 0, 'MPEG2 Xing mono file ok' );
    is( $info->{xing_frames}, 30, 'MPEG2 Xing mono frames ok' );    
}

# MPEG2 Xing stereo file to test xing_offset
{
    my $s = Audio::Scan->scan_info( _f('no-tags-mp2l3-vbr.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{stereo}, 1, 'MPEG2 Xing stereo file ok' );
    is( $info->{xing_frames}, 30, 'MPEG2 Xing stereo frames ok' );
    is( $info->{vbr}, 1, 'MPEG2 Xing vbr ok' );
}

# VBRI mono file
{
    my $s = Audio::Scan->scan_info( _f('no-tags-vbri-mono.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{stereo}, 0, 'VBRI mono file ok' );
    
    # XXX: VBRI mono files do not seem to put the VBRI tag at the correct place
}

# VBRI stereo file
{
    my $s = Audio::Scan->scan_info( _f('no-tags-vbri-stereo.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{vbri_delay}, 2353, 'VBRI delay ok' );
    is( $info->{bitrate}, 61000, 'VBRI bitrate ok' );
    is( $info->{song_length_ms}, 1071, 'VBRI duration ok' );
}

### ID3 tag tests

# ID3v1
{
    my $s = Audio::Scan->scan( _f('v1.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v1', 'ID3v1 version ok' );
    is( $tags->{TPE1}, 'Artist Name', 'ID3v1 artist ok' );
    is( $tags->{TIT2}, 'Track Title', 'ID3v1 title ok' );
    is( $tags->{TALB}, 'Album Name', 'ID3v1 album ok' );
    is( $tags->{TDRC}, 2009, 'ID3v1 year ok' );
    is( $tags->{TCON}, 'Ambient', 'ID3v1 genre ok' );
    is( $tags->{COMM}->[2], 'This is a comment', 'ID3v1 comment ok' );
}

# ID3v1.1 (adds track number)
{
    my $s = Audio::Scan->scan( _f('v1.1.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v1.1', 'ID3v1.1 version ok' );
    is( $tags->{TPE1}, 'Artist Name', 'ID3v1.1 artist ok' );
    is( $tags->{TIT2}, 'Track Title', 'ID3v1.1 title ok' );
    is( $tags->{TALB}, 'Album Name', 'ID3v1.1 album ok' );
    is( $tags->{TDRC}, 2009, 'ID3v1.1 year ok' );
    is( $tags->{TCON}, 'Ambient', 'ID3v1.1 genre ok' );
    is( $tags->{COMM}->[2], 'This is a comment', 'ID3v1.1 comment ok' );
    is( $tags->{TRCK}, 16, 'ID3v1.1 track number ok' );
}

# ID3v1 with ISO-8859-1 encoding
{
    my $s = Audio::Scan->scan_tags( _f('v1-iso-8859-1.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 3 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $raks, 'ID3v1 ISO-8859-1 artist ok' );
        is( $tags->{TIT2}, $raks, 'ID3v1 ISO-8859-1 title ok' );
        is( $tags->{TALB}, $raks, 'ID3v1 ISO-8859-1 album ok' );
    }
    
    # Make sure it's been converted to UTF-8
    ok( utf8::is_utf8( $tags->{TPE1} ), 'ID3v1 ISO-8859-1 artist converted to UTF-8 ok' );
}

# ID3v1 with UTF-8 encoding (no standard encoding is defined for v1 so we try to support it)
{
    my $s = Audio::Scan->scan_tags( _f('v1-utf8.mp3') );
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 3 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $raks, 'ID3v1 UTF-8 artist ok' );
        is( $tags->{TIT2}, $raks, 'ID3v1 UTF-8 title ok' );
        is( $tags->{TALB}, $raks, 'ID3v1 UTF-8 album ok' );
    }
    
    # Make sure it's been converted to UTF-8
    ok( utf8::is_utf8( $tags->{TPE1} ), 'ID3v1 UTF-8 artist converted to UTF-8 ok' );
}

# ID3v2.2 (libid3tag converts them to v2.4-equivalent tags)
{
    my $s = Audio::Scan->scan( _f('v2.2.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.2.0', 'ID3v2.2 version ok' );
    is( $tags->{TPE1}, 'Pudge', 'ID3v2.2 artist ok' );
    is( $tags->{TIT2}, 'Test v2.2.0', 'ID3v2.2 title ok' );
    is( $tags->{TDRC}, 1998, 'ID3v2.2 year ok' );
    is( $tags->{TCON}, 'Sound Clip', 'ID3v2.2 genre ok' );
    is( $tags->{COMM}->[0], 'eng', 'ID3v2.2 comment language ok' );
    is( $tags->{COMM}->[2], 'All Rights Reserved', 'ID3v2.2 comment ok' );
    is( $tags->{TRCK}, 2, 'ID3v2.2 track number ok' );
}

# ID3v2.2 with multiple comment tags
{
    my $s = Audio::Scan->scan_tags( _f('v2.2-multiple-comm.mp3') );
    
    my $tags = $s->{tags};

    is( scalar @{ $tags->{COMM} }, 4, 'ID3v2.2 4 comment tags ok' );
    is( $tags->{COMM}->[1]->[1], 'iTunNORM', 'ID3v2.2 iTunNORM ok' );
    is( $tags->{COMM}->[2]->[1], 'iTunes_CDDB_1', 'ID3v2.2 iTunes_CDDB_1 ok' );
    is( $tags->{COMM}->[3]->[1], 'iTunes_CDDB_TrackNumber', 'ID3v2.2 iTunes_CDDB_TrackNumber ok' );
}

# ID3v2.2 from iTunes 8.1, full of non-standard frames
{
    my $s = Audio::Scan->scan( _f('v2.2-itunes81.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $tags->{TENC}, 'iTunes 8.1', 'ID3v2.2 from iTunes 8.1 ok' );
    is( $tags->{USLT}->[2], 'This is the lyrics field from iTunes.', 'iTunes 8.1 USLT ok' );
    is( $tags->{TCMP}, 1, 'iTunes 8.1 TCP ok' );
    is( $tags->{TSO2}, 'Album Artist Sort', 'iTunes 8.1 TS2 ok' );
    is( $tags->{TSOA}, 'Album Sort', 'iTunes 8.1 TSA ok' );
    is( $tags->{TSOC}, 'Composer Sort', 'iTunes 8.1 TSC ok' );
    is( $tags->{TSOP}, 'Artist Name Sort', 'iTunes 8.1 TSP ok' );
    is( $tags->{TSOT}, 'Track Title Sort', 'iTunes 8.1 TST ok' );
    is( ref $tags->{RVAD}, 'ARRAY', 'iTunes 8.1 RVA ok' );
    is( $tags->{RVAD}->[0], '-2.119539 dB', 'iTunes 8.1 RVA right ok' );
    is( $tags->{RVAD}->[1], '0.000000', 'iTunes 8.1 RVA right peak ok' );
    is( $tags->{RVAD}->[2], '-2.119539 dB', 'iTunes 8.1 RVA left ok' );
    is( $tags->{RVAD}->[3], '0.000000', 'iTunes 8.1 RVA left peak ok' );
}

# ID3v2.3
{
    my $s = Audio::Scan->scan( _f('v2.3.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3v2.3 version ok' );
    is( $tags->{TPE1}, 'Artist Name', 'ID3v2.3 artist ok' );
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.3 title ok' );
    is( $tags->{TALB}, 'Album Name', 'ID3v2.3 album ok' );
    is( $tags->{TCON}, 'Ambient', 'ID3v2.3 genre ok' );
    is( $tags->{TRCK}, '02/10', 'ID3v2.3 track number ok' );
    is( $tags->{'TAGGING TIME'}, '2009-03-16T17:58:23', 'ID3v2.3 TXXX ok' ); # TXXX tag
    
    # Make sure TDRC is present and TYER has been removed
    is( $tags->{TDRC}, 2009, 'ID3v2.3 date ok' );
    is( $tags->{TYER}, undef, 'ID3v2.3 TYER removed ok' );
}

# ID3v2.3 ISO-8859-1
{
    my $s = Audio::Scan->scan( _f('v2.3-iso-8859-1.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3v2.3 version ok' );
    
    SKIP:
    {
        skip 'Encode is not available', 3 unless $HAS_ENCODE;
        my $a = Encode::decode_utf8('Ester Koèièková a Lubomír Nohavica');
        my $b = Encode::decode_utf8('Ester Koèièková a Lubomír Nohavica s klavírem');
        my $c = Encode::decode_utf8('Tøem sestrám');
    
    
        is( $tags->{TPE1}, $a, 'ID3v2.3 ISO-8859-1 artist ok' );
        is( $tags->{TALB}, $b, 'ID3v2.3 ISO-8859-1 album ok' );
        is( $tags->{TIT2}, $c, 'ID3v2.3 ISO-8859-1 title ok' );
    }
    
    # Make sure it's been converted to UTF-8
    is( utf8::valid( $tags->{TPE1} ), 1, 'ID3v2.3 ISO-8859-1 is valid UTF-8' );
}

# ID3v2.3 UTF-16 with no BOM (defaults to LE), bug 14728
{
    my $s = Audio::Scan->scan_tags( _f('v2.3-utf16any.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TPE1}, "Guns N' Roses", 'ID3v2.3 UTF-16 title ok' );
    is( $tags->{TALB}, 'Use Your Illusion II', 'ID3v2.3 UTF-16 title ok' );
}

# ID3v2.3 UTF-16BE
{
    my $s = Audio::Scan->scan_tags( _f('v2.3-utf16be.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $pate, 'ID3v2.3 UTF-16BE artist ok' );
    }
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.3 UTF-16BE title ok' );
    
    is( utf8::valid( $tags->{TPE1} ), 1, 'ID3v2.3 UTF-16BE is valid UTF-8' );
}

# ID3v2.3 UTF-16LE
{
    my $s = Audio::Scan->scan_tags( _f('v2.3-utf16le.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $pate, 'ID3v2.3 UTF-16LE artist ok' );
    }
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.3 UTF-16LE title ok' );
    
    is( utf8::valid( $tags->{TPE1} ), 1, 'ID3v2.3 UTF-16LE is valid UTF-8' );
}

# ID3v2.3 mp3HD, make sure we ignore XHD3 frame properly
{
    my $s = Audio::Scan->scan( _f('v2.3-mp3HD.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{audio_offset}, 57956, 'mp3HD offset ok' );
    is( $tags->{TIT2}, 'mp3HD is evil', 'mp3HD tags ok' );
    is( $tags->{XHD3}, undef, 'mp3HD XHD3 frame ignored' );
}

# ID3v2.3 with empty WXXX tag
{
    my $s = Audio::Scan->scan( _f('v2.3-empty-wxxx.mp3') );
    
    my $tags = $s->{tags};
    
    is( !exists( $tags->{''} ), 1, 'ID3v2.3 empty WXXX ok' );
}

# ID3v2.3 with empty TCON tag
# Also has empty TENC, WXXX, TCOP, TOPE, TCOM, TYER, TALB
{
    my $s = Audio::Scan->scan( _f('v2.3-empty-tcon.mp3') );
    
    my $tags = $s->{tags};
    
    is( !exists( $tags->{TCON} ), 1, 'ID3v2.3 empty TCON ok' );
    is( $tags->{TRCK}, '03/09', 'ID3v2.3 empty TCON track ok' );
    is( !exists( $tags->{TDRC} ), 1, 'ID3v2.3 empty TYER ok' );
    is( $tags->{TENC}, undef, 'ID3v2.3 empty TENC ok' );
    is( $tags->{TOPE}, undef, 'ID3v2.3 empty TOPE ok' );
    is( $tags->{TCOP}, undef, 'ID3v2.3 empty TCOP ok' );
    is( $tags->{TCOM}, undef, 'ID3v2.3 empty TCOM ok' );
    is( $tags->{TALB}, undef, 'ID3v2.3 empty TALB ok' );
}

# ID3v2.3 from iTunes with non-standard tags with spaces
{
    my $s = Audio::Scan->scan( _f('v2.3-itunes81.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3v2.3 from iTunes ok' );
    is( $tags->{TSOT}, 'Track Title Sort', 'ID3v2.3 invalid iTunes frame ok' );
    is( ref $tags->{RVAD}, 'ARRAY', 'iTunes 8.1 RVAD ok' );
    is( $tags->{RVAD}->[0], '-2.119539 dB', 'iTunes 8.1 RVAD right ok' );
    is( $tags->{RVAD}->[1], '0.000000', 'iTunes 8.1 RVAD right peak ok' );
    is( $tags->{RVAD}->[2], '-2.119539 dB', 'iTunes 8.1 RVAD left ok' );
    is( $tags->{RVAD}->[3], '0.000000', 'iTunes 8.1 RVAD left peak ok' );
}

# ID3v2.3 corrupted text, from http://bugs.gentoo.org/show_bug.cgi?id=210564
# The TBPM frame has an odd number of text bytes but specifies UTF-16 encoding, it
# should not read into the next frame (TCON)
{
    my $s = Audio::Scan->scan( _f('gentoo-bug-210564.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TRCK}, 26, 'ID3v2.3 corrupted frame TRCK ok' );
    is( $tags->{TBPM}, 0, 'ID3v2.3 corrupted frame TBPM ok' );
    is( $tags->{TALB}, 'aikosingles', 'ID3v2.3 corrupted frame TALB ok' );
    is( $tags->{TCON}, 'JPop', 'ID3v2.3 corrupted frame TCON ok' );
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        my $title = Encode::decode_utf8("花火");
        is( $tags->{TIT2}, $title, 'ID3v2.3 corrupted title ok' );
    }
}

# ID3v2.4
{
    my $s = Audio::Scan->scan( _f('v2.4.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.4.0, ID3v1', 'ID3v2.4 version ok' );
    is( $tags->{TPE1}, 'Artist Name', 'ID3v2.4 artist ok' );
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 title ok' );
    is( $tags->{TALB}, 'Album Name', 'ID3v2.4 album ok' );
    is( $tags->{TCON}, 'Ambient', 'ID3v2.4 genre ok' );
    is( $tags->{TRCK}, '02/10', 'ID3v2.4 track number ok' );
    is( $tags->{PCNT}, 256, 'ID3v2.4 playcount field ok' );
    is( $tags->{POPM}->[0]->[0], 'foo@foo.com', 'ID3v2.4 POPM #1 ok' );
    is( $tags->{POPM}->[1]->[2], 7, 'ID3v2.4 POPM #2 ok' );
    is( $tags->{RVA2}->[0], 'normalize', 'ID3v2.4 RVA2 ok' );
    is( $tags->{RVA2}->[1], 1, 'ID3v2.4 RVA2 channel ok' );
    is( $tags->{RVA2}->[2], '4.972656 dB', 'ID3v2.4 RVA2 adjustment ok' );
    is( $tags->{RVA2}->[3], '0.000000 dB', 'ID3v2.4 RVA2 peak ok' );
    is( $tags->{TBPM}, 120, 'ID3v2.4 BPM field ok' );
    is( $tags->{UFID}->[0], 'foo@foo.com', 'ID3v2.4 UFID owner id ok' );
    is( $tags->{UFID}->[1], 'da39a3ee5e6b4b0d3255bfef95601890afd80709', 'ID3v2.4 UFID ok' );
    is( $tags->{'USER FRAME'}, 'User Data', 'ID3v2.4 TXXX ok' );
    is( $tags->{WCOM}, 'http://www.google.com', 'ID3v2.4 WCOM ok' );
    is( $tags->{'USER URL'}, 'http://www.google.com', 'ID3v2.4 WXXX ok' );
    
    # XXX: 2 WOAR frames
}

# ID3v2.4 with negative RVA2
{
    my $s = Audio::Scan->scan_tags( _f('v2.4-rva2-neg.mp3') );
    
    my $tags = $s->{tags};
    is( $tags->{RVA2}->[2], '-2.123047 dB', 'ID3v2.4 negative RVA2 adjustment ok' );
}

# Multiple RVA2 tags with peak, from mp3gain
{
    my $s = Audio::Scan->scan( _f('v2.4-rva2-mp3gain.mp3') );
    
    my $tags = $s->{tags};
    is( ref $tags->{RVA2}, 'ARRAY', 'mp3gain RVA2 ok' );
    is( $tags->{RVA2}->[0]->[0], 'track', 'mp3gain track RVA2 ok' );
    is( $tags->{RVA2}->[0]->[2], '-7.478516 dB', 'mp3gain track gain ok' );
    is( $tags->{RVA2}->[0]->[3], '1.172028 dB', 'mp3gain track peak ok' );
    is( $tags->{RVA2}->[1]->[0], 'album', 'mp3gain album RVA2 ok' );
    is( $tags->{RVA2}->[1]->[2], '-7.109375 dB', 'mp3gain album gain ok' );
    is( $tags->{RVA2}->[1]->[3], '1.258026 dB', 'mp3gain album peak ok' );
}

# ID3v2.4 ISO-8859-1
{
    my $s = Audio::Scan->scan_tags( _f('v2.4-iso-8859-1.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $pate, 'ID3v2.4 ISO-8859-1 artist ok' );
    }
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 ISO-8859-1 title ok' );
}

# ID3v2.4 UTF-16BE
{
    my $s = Audio::Scan->scan_tags( _f('v2.4-utf16be.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $pate, 'ID3v2.4 UTF-16BE artist ok' );
    }
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 UTF-16BE title ok' );
    is( $tags->{TCON}, 'Ambient', 'ID3v2.4 genre in (NN) format ok' );
}

# ID3v2.4 UTF-16LE
{
    my $s = Audio::Scan->scan_tags( _f('v2.4-utf16le.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        is( $tags->{TPE1}, $pate, 'ID3v2.4 UTF-16LE artist ok' );
    }
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 UTF-16LE title ok' );
}

# ID3v2.4 UTF-8
{
    my $s = Audio::Scan->scan_tags( _f('v2.4-utf8.mp3') );
    
    my $tags = $s->{tags};
    
    SKIP:
    {
        skip 'Encode is not available', 2 unless $HAS_ENCODE;
        my $a = Encode::decode_utf8('ЪЭЯ');
        my $b = Encode::decode_utf8('ΈΤ');
        my $c = Encode::decode_utf8('γζ');
    
        is( $tags->{TPE1}, $a, 'ID3v2.4 UTF-8 title ok' );
        is( $tags->{$b}, $c, 'ID3v2.4 UTF-8 TXXX key/value ok' );
    }
}

# ID3v2.4 from iTunes with non-standard tags with spaces
{
    my $s = Audio::Scan->scan( _f('v2.4-itunes81.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.4.0', 'ID3v2.4 from iTunes ok' );
    is( $tags->{TSOT}, 'Track Title Sort', 'ID3v2.4 invalid iTunes TST frame ok' );
    is( $tags->{TCON}, 'Metal', 'ID3v2.4 TCON with (9) ok' );
    is( $tags->{RVA2}->[0], '', 'ID3v2.4 RVA2 ok' );
    is( $tags->{RVA2}->[1], 1, 'ID3v2.4 RVA2 channel ok' );
    is( $tags->{RVA2}->[2], '-2.109375 dB', 'ID3v2.4 RVA2 adjustment ok' );
    is( $tags->{RVA2}->[3], '0.000000 dB', 'ID3v2.4 RVA2 peak ok' );
}

# ID3v2.4 with JPEG APIC
{
    my $s = Audio::Scan->scan( _f('v2.4-apic-jpg.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{APIC}, 'ARRAY', 'ID3v2.4 APIC JPEG frame is array' );
    is( $tags->{APIC}->[0], 'image/jpeg', 'ID3v2.4 APIC JPEG mime type ok' );
    is( $tags->{APIC}->[1], 3, 'ID3v2.4 APIC JPEG picture type ok' );
    is( $tags->{APIC}->[2], 'This is the front cover description', 'ID3v2.4 APIC JPEG description ok' );
    is( length( $tags->{APIC}->[3] ), 2103, 'ID3v2.4 APIC JPEG picture length ok' );
    is( unpack( 'H*', substr( $tags->{APIC}->[3], 0, 4 ) ), 'ffd8ffe0', 'ID3v2.4 APIC JPEG picture data ok ');
}

# Test AUDIO_SCAN_NO_ARTWORK
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    
    my $s = Audio::Scan->scan( _f('v2.4-apic-jpg.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{APIC}->[3], 2103, 'ID3v2.4 APIC JPEG picture with AUDIO_SCAN_NO_ARTWORK=1 ok ');
    is( $tags->{APIC}->[4], 351, 'ID3v2.4 APIC JPEG picture with AUDIO_SCAN_NO_ARTWORK=1 offset value ok' );
}

# Test setting AUDIO_SCAN_NO_ARTWORK to 0
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 0;
    
    my $s = Audio::Scan->scan( _f('v2.4-apic-jpg.mp3') );
    
    my $tags = $s->{tags};
    
    is( length( $tags->{APIC}->[3] ), 2103, 'ID3v2.4 APIC JPEG picture with AUDIO_SCAN_NO_ARTWORK=0 ok' );
}

# ID3v2.4 with PNG APIC
{
    my $s = Audio::Scan->scan( _f('v2.4-apic-png.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{APIC}, 'ARRAY', 'ID3v2.4 APIC PNG frame is array' );
    is( $tags->{APIC}->[0], 'image/png', 'ID3v2.4 APIC PNG mime type ok' );
    is( $tags->{APIC}->[1], 3, 'ID3v2.4 APIC PNG picture type ok' );
    is( $tags->{APIC}->[2], 'This is the front cover description', 'ID3v2.4 APIC PNG description ok' );
    is( length( $tags->{APIC}->[3] ), 58618, 'ID3v2.4 APIC PNG picture length ok' );
    is( unpack( 'H*', substr( $tags->{APIC}->[3], 0, 4 ) ), '89504e47', 'ID3v2.4 APIC PNG picture data ok ');
}

# ID3v2.4 with multiple APIC
{
    my $s = Audio::Scan->scan( _f('v2.4-apic-multiple.mp3') );
    
    my $tags = $s->{tags};
    
    my $png = $tags->{APIC}->[0];
    my $jpg = $tags->{APIC}->[1];
    
    is( ref $png, 'ARRAY', 'ID3v2.4 APIC PNG frame is array' );
    is( $png->[0], 'image/png', 'ID3v2.4 APIC PNG mime type ok' );
    is( $png->[1], 3, 'ID3v2.4 APIC PNG picture type ok' );
    is( $png->[2], 'This is the front cover description', 'ID3v2.4 APIC PNG description ok' );
    is( length( $png->[3] ), 58618, 'ID3v2.4 APIC PNG picture length ok' );
    is( unpack( 'H*', substr( $png->[3], 0, 4 ) ), '89504e47', 'ID3v2.4 APIC PNG picture data ok ');
    
    is( ref $jpg, 'ARRAY', 'ID3v2.4 APIC JPEG frame is array' );
    is( $jpg->[0], 'image/jpeg', 'ID3v2.4 APIC JPEG mime type ok' );
    is( $jpg->[1], 4, 'ID3v2.4 APIC JPEG picture type ok' );
    is( $jpg->[2], 'This is the back cover description', 'ID3v2.4 APIC JPEG description ok' );
    is( length( $jpg->[3] ), 2103, 'ID3v2.4 APIC JPEG picture length ok' );
    is( unpack( 'H*', substr( $jpg->[3], 0, 4 ) ), 'ffd8ffe0', 'ID3v2.4 APIC JPEG picture data ok ');
}

# ID3v2.4 with GEOB
{
    my $s = Audio::Scan->scan( _f('v2.4-geob.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{GEOB}, 'ARRAY', 'ID3v2.4 GEOB is array' );
    is( $tags->{GEOB}->[0], 'text/plain', 'ID3v2.4 GEOB mime type ok' );
    is( $tags->{GEOB}->[1], 'eyeD3.txt', 'ID3v2.4 GEOB filename ok' );
    is( $tags->{GEOB}->[2], 'eyeD3 --help output', 'ID3v2.4 GEOB content description ok' );
    is( length( $tags->{GEOB}->[3] ), 6207, 'ID3v2.4 GEOB length ok' );
    is( substr( $tags->{GEOB}->[3], 0, 6 ), "\nUsage", 'ID3v2.4 GEOB content ok' );
}

# ID3v2.4 with multiple GEOB
{
    my $s = Audio::Scan->scan( _f('v2.4-geob-multiple.mp3') );
    
    my $tags = $s->{tags};
    
    my $a = $tags->{GEOB}->[0];
    my $b = $tags->{GEOB}->[1];
    
    is( ref $a, 'ARRAY', 'ID3v2.4 GEOB multiple A is array' );
    is( $a->[0], 'text/plain', 'ID3v2.4 GEOB multiple A mime type ok' );
    is( $a->[1], 'eyeD3.txt', 'ID3v2.4 GEOB multiple A filename ok' );
    is( $a->[2], 'eyeD3 --help output', 'ID3v2.4 GEOB multiple A content description ok' );
    is( length( $a->[3] ), 6207, 'ID3v2.4 GEOB multiple A length ok' );
    is( substr( $a->[3], 0, 6 ), "\nUsage", 'ID3v2.4 GEOB multiple A content ok' );
    
    is( ref $b, 'ARRAY', 'ID3v2.4 GEOB multiple B is array' );
    is( $b->[0], 'text/plain', 'ID3v2.4 GEOB multiple B mime type ok' );
    is( $b->[1], 'genres.txt', 'ID3v2.4 GEOB multiple B filename ok' );
    is( $b->[2], 'eyeD3 --list-genres output', 'ID3v2.4 GEOB multiple B content description ok' );
    is( length( $b->[3] ), 4087, 'ID3v2.4 GEOB multiple B length ok' );
    is( substr( $b->[3], 0, 10 ), '  0: Blues', 'ID3v2.4 GEOB multiple B content ok' );
}

# ID3v2.4 with TIPL frame that has multiple strings
{
    my $s = Audio::Scan->scan( _f('v2.4-tipl.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{TIPL}, 'ARRAY', 'ID3v2.4 TIPL array ok' );
    is( $tags->{TIPL}->[0], 'producer', 'ID3v2.4 TIPL string 1 ok' );
    is( $tags->{TIPL}->[1], 'Steve Albini', 'ID3v2.4 TIPL string 2 ok' );
    is( $tags->{TIPL}->[2], 'engineer', 'ID3v2.4 TIPL string 3 ok' );
    is( $tags->{TIPL}->[3], 'Steve Albini', 'ID3v2.4 TIPL string 4 ok' );
}

# ID3v2.4 + APEv2 tags, some tags are multiple
{
    my $s = Audio::Scan->scan( _f('v2.4-ape.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 with APEv2 tag ok' );
    is( $tags->{APE_TAGS_SUCK}, 1, 'APEv2 tag ok' );
    is( ref $tags->{POPULARIMETER}, 'ARRAY', 'APEv2 POPULARIMETER tag ok' );
    is( $tags->{POPULARIMETER}->[0], 'foo@foo.com|150|1234567890', 'APEv2 POPULARIMETER tag 1 ok' );
    is( $tags->{POPULARIMETER}->[1], 'foo2@foo.com|30|7', 'APEv2 POPULARIMETER tag 2 ok' );
}

# iTunes-tagged file with invalid length frames
{
	my $s = Audio::Scan->scan_tags( _f('v2.4-itunes-broken-syncsafe.mp3') );
	
	my $tags = $s->{tags};
	
	is( scalar( keys %{$tags} ), 10, 'iTunes broken syncsafe read all tags ok' );
	is( scalar( @{ $tags->{COMM} } ), 4, 'iTunes broken syncsafe read all COMM frames ok' );
	is( length( $tags->{APIC}->[3] ), 29614, 'iTunes broken syncsafe read APIC ok' );
}

# v2.2 PIC frame
{
    my $s = Audio::Scan->scan_tags( _f('v2.2-pic.mp3') );
    
    my $tags = $s->{tags};
    
    is( scalar( @{ $tags->{APIC} } ), 4, 'v2.2 PIC fields ok' );
    is( $tags->{APIC}->[0], 'PNG', 'v2.2 PIC image format field ok' );
    is( $tags->{APIC}->[1], 0, 'v2.2 PIC picture type ok' );
    is( $tags->{APIC}->[2], '', 'v2.2 PIC description ok' );
    is( length( $tags->{APIC}->[3] ), 61007, 'v2.2 PIC data length ok' );
    is( unpack( 'H*', substr( $tags->{APIC}->[3], 0, 4 ) ), '89504e47', 'v2.2 PIC PNG picture data ok ');
} 

# Scan via a filehandle
{
    open my $fh, '<', _f('v2.4.mp3');
    
    my $s = Audio::Scan->scan_fh( mp3 => $fh );
    
    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{id3_version}, 'ID3v2.4.0, ID3v1', 'ID3v2.4 version ok via filehandle' );
    is( $tags->{TPE1}, 'Artist Name', 'ID3v2.4 artist ok via filehandle' );
    is( $tags->{TIT2}, 'Track Title', 'ID3v2.4 title ok via filehandle' );
    
    close $fh;
}

# Find frame offset
{
    my $offset = Audio::Scan->find_frame( _f('no-tags-no-xing-vbr.mp3'), 1000 );
    
    is( $offset, 27504, 'Find frame non-Xing ok' );
    
    # Find first frame past Xing tag using special absolute byte offset support
    # via negative number
    $offset = Audio::Scan->find_frame( _f('no-tags-mp1l3-vbr.mp3'), -1 );
    
    is( $offset, 576, 'Find frame past Xing tag ok' );
}

# Test very close to the end of the file
{
    open my $fh, '<', _f('no-tags-no-xing-vbr.mp3');
    
    my $offset = Audio::Scan->find_frame_fh( mp3 => $fh, 4950 );
    
    is( $offset, 132860, 'Find frame via filehandle ok' );
    
    close $fh;
}

# Seeking with Xing TOC
{
    # Xing TOC will be used @ 47.8%
    my $offset = Audio::Scan->find_frame( _f('v2.3-itunes81.mp3' ), 600 );
    is( $offset, 15403, 'Find frame with Xing TOC ok' );
}

# Bug 12409, file with just enough junk data before first audio frame
# to require a second buffer read
{
    my $s = Audio::Scan->scan_info( _f('v2.3-null-bytes.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{audio_offset}, 4896, 'Bug 12409 audio offset ok' );
    is( $info->{bitrate}, 128000, 'Bug 12409 bitrate ok' );
    is( $info->{lame_encoder_version}, 'LAME3.96r', 'Bug 12409 encoder version ok' );
    is( $info->{song_length_ms}, 244382, 'Bug 12409 song length ok' );
}

# Bug 9942, APE tag with no ID3v1 tag and multiple tags
{
    my $s = Audio::Scan->scan( _f('ape-no-v1.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{ape_version}, 'APEv2', 'APE no ID3v1 ok' );
    
    is( $tags->{ALBUM}, '13 Blues for Thirteen Moons', 'APE no ID3v1 ALBUM ok' );
    is( ref $tags->{ARTIST}, 'ARRAY', 'APE no ID3v1 ARTIST ok' );
    is( $tags->{ARTIST}->[0], 'artist1', 'APE no ID3v1 artist1 ok' );
    is( $tags->{ARTIST}->[1], 'artist2', 'APE no ID3v1 artist2 ok' );
}

# Bug 13921, ID3v2.3 with experimental XSOP tag that should be treated as text
# This file also contains a TYER and TDAT tag that should be properly converted to TDRC
{
    my $s = Audio::Scan->scan_tags( _f('v2.3-xsop.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{XSOP}, 'Addy, Obo', 'Bug 13921, v2.3 XSOP ok' );
    is( $tags->{TDRC}, '1992-02-14T13:46', 'v2.3 TYER/TDAT converted to TDRC ok' );
    is( $tags->{PRIV}->[0]->[0], 'PeakValue', 'v2.3 PRIV frame 1 key ok' );
    is( length($tags->{PRIV}->[0]->[1]), 4, 'v2.3 PRIV frame 1 value ok' );
    is( $tags->{PRIV}->[1]->[0], 'AverageLevel', 'v2.3 PRIV frame 2 key ok' );
    is( length($tags->{PRIV}->[1]->[1]), 4, 'v2.3 PRIV frame 2 value ok' );
}

# MPEG 2.0 with Xing header, bitrate calculation was broken
{
	my $s = Audio::Scan->scan_info( _f('v2.2-mpeg20-xing.mp3') );
	
	my $info = $s->{info};
	
	is( $info->{bitrate}, 69000, 'MPEG 2.0 Xing bitrate ok' );
}

# Bug 14705, 9th frame is corrupt, but previous 8 should be returned ok
{
    my $s = Audio::Scan->scan( _f('v2.4-corrupt-frame.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TPE1}, 'Miles Davis', 'ID3v2.4 corrupt frame TPE1 ok' );
    is( $tags->{TALB}, "Ascenseur pour l'\xE9chafaud", 'ID3v2.4 corrupt frame TALB ok' );
    is( $tags->{TCON}, 'Jazz', 'ID3v2.4 corrupt frame TCON ok' );
    is( $tags->{TENC}, 'iTunes v1.1', 'ID3v2.4 corrupt frame TENC ok' );
    is( $tags->{TIT2}, 'Evasion de Julien', 'ID3v2.4 corrupt frame TIT2 ok' );
    is( $tags->{TRCK}, '23/26', 'ID3v2.4 corrupt frame TRCK ok' );
    is( $tags->{COMM}->[2], 'Diskapif', 'ID3v2.4 corrupt frame COMM ok' );
    is( length( $tags->{APIC}->[3] ), 33133, 'ID3v2.4 corrupt frame APIC ok' );
}

# Bug 8380, ID3v2 + ID3v1
{
    my $s = Audio::Scan->scan( _f('v2-v1.mp3') );
    
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0, ID3v1', 'v2-v1 version ok' );
    
    is( $tags->{TPE1}, 'AC/DC', 'v2-v1 ID3v1 TPE1 ok' );
    is( $tags->{REPLAYGAIN_TRACK_GAIN}, '-9.15 dB', 'v2-v1 ID3v2 TXXX ok' );
}

# Bug 15115, LINK frame, data will be wrong but shouldn't crash
{
    my $s = Audio::Scan->scan( _f('v2.3-link-frame.mp3') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TALB}, 'Bob Marley & Peter Tosh', 'ID3v2.3 LINK frame TALB ok' );
    is( ref $tags->{LINK}, 'ARRAY', 'ID3v2.3 LINK frame is array' );
    is( $tags->{LINK}->[0], 'WCO', 'ID3v2.3 LINK frame frameid ok' );
    like( $tags->{LINK}->[1], qr{^http://www.emusic.com}, 'ID3v2.3 LINK frame URL ok' );
}

# Bug 15196, multiple TCON genre values (v2.4)
{
    my $s = Audio::Scan->scan( _f('v2.4-multiple-tcon.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.4 multiple TCON is array' );
    is( $tags->{TCON}->[0], 'Rock', 'ID3v2.4 multiple TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Live', 'ID3v2.4 multiple TCON value 2 ok' );
}

# Multiple TCON genre in v2.4 with numeric only
{
    my $s = Audio::Scan->scan( _f('v2.4-multiple-tcon-numeric.mp3') );
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.4 multiple numeric TCON is array' );
    is( $tags->{TCON}->[0], 'A Capella', 'ID3v2.4 multiple numeric TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Sonata', 'ID3v2.4 multiple numeric TCON value 2 ok' );
}

# Bug 3998, multiple TCON genre values (v2.3 UTF-16)
{
    my $s = Audio::Scan->scan( _f('v2.3-multiple-tcon.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.3 multiple TCON is array' );
    is( $tags->{TCON}->[0], 'Live', 'ID3v2.3 multiple TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Pop', 'ID3v2.3 multiple TCON value 2 ok' );
}

# Multiple TCON genre values in v2.3 numeric form (51)(39)
{
    my $s = Audio::Scan->scan( _f('v2.3-multiple-tcon-numeric.mp3') );
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.3 multiple numeric TCON is array' );
    is( $tags->{TCON}->[0], 'Techno-Industrial', 'ID3v2.3 multiple numeric TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Noise', 'ID3v2.3 multiple numeric TCON value 2 ok' );
}

# Multiple TCON genre values in v2.3 with text (55)(Text)
{
    my $s = Audio::Scan->scan( _f('v2.3-multiple-tcon-text.mp3') );
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.3 multiple numeric+text TCON is array' );
    is( $tags->{TCON}->[0], 'Dream', 'ID3v2.3 multiple numeric+text TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Text', 'ID3v2.3 multiple numeric+text TCON value 2 ok' );
}

# Multiple TCON genre values in v2.3 with RX/CR special keywords
{
    my $s = Audio::Scan->scan( _f('v2.3-multiple-tcon-rx-cr.mp3') );
    my $tags = $s->{tags};
    
    is( ref $tags->{TCON}, 'ARRAY', 'ID3v2.3 multiple RX/CR TCON is array' );
    is( $tags->{TCON}->[0], 'Remix', 'ID3v2.3 multiple RX/CR TCON value 1 ok' );
    is( $tags->{TCON}->[1], 'Cover', 'ID3v2.3 multiple RX/CR TCON value 2 ok' );
}

# Bug 15197, MPEG-2 Layer 3 bitrate calculation
{
    my $s = Audio::Scan->scan( _f('v2.3-mp2l3-64k-22khz.mp3') );
    
    my $info = $s->{info};
    
    is( $info->{bitrate}, 64000, 'MPEG-2 Layer 3 bitrate ok' );
    is( $info->{samplerate}, 22050, 'MPEG-2 Layer 3 sample rate ok' );
    is( $info->{song_length_ms}, 364, 'MPEG-2 Layer 3 duration ok' );
}

# RGAD frame parsing
{
    my $s = Audio::Scan->scan( _f('v2.3-rgad.mp3') );
    
    my $tags = $s->{tags};
    
    is( ref $tags->{RGAD}, 'HASH', 'RGAD frame is a hash' );
    is( $tags->{RGAD}->{peak}, '0.999020', 'RGAD peak ok' );
    is( $tags->{RGAD}->{track_originator}, 3, 'RGAD track originator ok' );
    is( $tags->{RGAD}->{track_gain}, '-5.700000 dB', 'RGAD track gain ok' );
    is( $tags->{RGAD}->{album_originator}, 3, 'RGAD album originator ok' );
    is( $tags->{RGAD}->{album_gain}, '-5.600000 dB', 'RGAD album gain ok' );
}

# v2.4 per-frame unsynchronisation
{
    my $s = Audio::Scan->scan( _f('v2.4-unsync.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TALB}, 'Album', 'v2.4 unsync TALB ok' );
    is( $tags->{TDRC}, 2009, 'v2.4 unsync TDRC ok' );
    is( $tags->{TIT2}, 'Title', 'v2.4 unsync TIT2 ok' );
    is( $tags->{TPE1}, 'Artist', 'v2.4 unsync TPE1 ok' );
}

# v2.3 whole tag unsynchronisation
{
    my $s = Audio::Scan->scan( _f('v2.3-unsync.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TALB}, 'Hydroponic Garden', 'v2.3 unsync TALB ok' );
    is( $tags->{TCON}, 'Ambient', 'v2.3 unsync TCON ok' );
    is( $tags->{TPE1}, 'Carbon Based Lifeforms', 'v2.3 unsync TPE1 ok' );
    is( $tags->{TPE2}, 'Carbon Based Lifeforms', 'v2.3 unsync TPE2 ok' );
    is( $tags->{TRCK}, 4, 'v2.3 unsync TRCK ok' );
}

# v2.3 frame compression
{
    my $s = Audio::Scan->scan( _f('v2.3-compressed-frame.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TIT2}, 'Compressed TIT2 Frame', 'v2.3 compressed frame ok' );
    is( $tags->{TPE1}, 'Artist Name', 'v2.3 frame after compressed frame ok' );
}

# v2.4 frame compression
{
    my $s = Audio::Scan->scan( _f('v2.4-compressed-frame.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TIT2}, 'Compressed TIT2 Frame', 'v2.4 compressed frame ok' );
    is( $tags->{TRCK}, '02/10', 'v2.4 frame after compressed frame ok' );
}

# v2.3 extended header
{
    my $s = Audio::Scan->scan_tags( _f('v2.3-ext-header.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TCON}, 'Blues', 'v2.3 extended header ok' );
}

# MCDI frame
{
    my $s = Audio::Scan->scan( _f('v2.3-mcdi.mp3') );
    my $tags = $s->{tags};
    
    is( length($tags->{MCDI}), 804, 'v2.3 MCDI ok' );
}

# ETCO frame, test file from http://www.blogarithms.com/index.php/archives/2008/01/01/etcotag/
{
    my $s = Audio::Scan->scan( _f('v2.3-etco.mp3') );
    my $tags = $s->{tags};
    
    my $etco = $tags->{ETCO};
    is( $etco->[0], 2, 'v2.3 ETCO time stamp format ok' );
    
    my $events = $etco->[1];
    is( $events->[0]->{type}, 3, 'v2.3 ETCO event type ok' );
    is( $events->[0]->{timestamp}, 152110, 'v2.3 ETCO timestamp ok' );
}

# SYLT frame
{
    my $s = Audio::Scan->scan( _f('v2.3-sylt.mp3') );
    my $tags = $s->{tags};
    
    my $sylt = $tags->{SYLT};
    is( $sylt->[0], 'XXX', 'v2.3 SYLT language ok' );
    is( $sylt->[1], 2, 'v2.3 SYLT time stamp format ok' );
    is( $sylt->[2], 1, 'v2.3 SYLT content type ok' );
    is( $sylt->[3], 'Converted from Lyrics3 v2.00', 'v2.3 SYLT description ok' );
    
    my $content = $sylt->[4];
    is( $content->[0]->{text}, "Let's talk about time", 'v2.3 SYLT text 1 ok' );
    is( $content->[0]->{timestamp}, 2000, 'v2.3 SYLT timestamp 1 ok' );
    is( $content->[-1]->{text}, '(Repeat)', 'v2.3 SYLT text -1 ok' );
    is( $content->[-1]->{timestamp}, 181000, 'v2.3 SYLT timestamp -1 ok' );
}

# invalid encoding bytes
{
    my $s = Audio::Scan->scan( _f('v2.3-invalid-encoding.mp3') );
    my $tags = $s->{tags};
    
    ok( !exists $tags->{TRCK}, 'v2.3 invalid encoding ok' );
}

# v2.3 encrypted frame
{
    my $s = Audio::Scan->scan( _f('v2.3-encrypted-frame.mp3') );
    my $tags = $s->{tags};
    
    ok( !exists $tags->{TIT2}, 'v2.3 encrypted frame is skipped' );
    is( $tags->{TPE1}, 'Artist Name', 'v2.3 frame after encrypted frame is ok' );
}

# v2.3 group id frame
{
    my $s = Audio::Scan->scan( _f('v2.3-group-id.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TIT2}, 'Track Title', 'v2.3 group id frame ok' );
    is( $tags->{TRCK}, '02/10', 'v2.3 frame after group id frame ok' );
}

# v2.4 encrypted frame
{
    my $s = Audio::Scan->scan( _f('v2.4-encrypted-frame.mp3') );
    my $tags = $s->{tags};
    
    ok( !exists $tags->{TIT2}, 'v2.4 encrypted frame is skipped' );
    is( $tags->{TRCK}, '02/10', 'v2.4 frame after encrypted frame is ok' );
}

# v2.4 group id frame
{
    my $s = Audio::Scan->scan( _f('v2.4-group-id.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TIT2}, 'Track Title', 'v2.4 group id frame ok' );
    is( $tags->{TRCK}, '02/10', 'v2.4 frame after group id frame ok' );
}

# v2.4 with UTF-8 encoded comment with empty null description
{
    my $s = Audio::Scan->scan( _f('v2.4-utf8-null-comment.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{COMM}->[0], 'eng', 'v2.4 UTF-8 null comment lang ok' );
    is( $tags->{COMM}->[1], '', 'v2.4 UTF-8 null comment description ok' );
    is( $tags->{COMM}->[2], 'Test 123', 'v2.4 UTF-8 null comment value ok' );
}

# v2.4 with unsynchronized APIC frame, check that the correct length is read
# in both artwork and no-artwork modes
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    my $s = Audio::Scan->scan( _f('v2.4-apic-unsync.mp3') );
    my $tags = $s->{tags};
    
    # This is not the actual length but it's OK since we don't unsync in no-artwork mode
    is( $tags->{APIC}->[3], 46240, 'v2.4 APIC unsync no-artwork length ok' );
    is( !defined $tags->{APIC}->[4], 1, 'v2.4 APIC unsync no-artwork has no offset ok' );
}

{
    my $s = Audio::Scan->scan( _f('v2.4-apic-unsync.mp3') );
    my $tags = $s->{tags};
    
    is( length( $tags->{APIC}->[3] ), 45984, 'v2.4 APIC unsync actual length ok' );
    is( unpack( 'H*', substr( $tags->{APIC}->[3], 0, 4 ) ), 'ffd8ffe0', 'v2.4 APIC unsync JPEG data ok' );
    is( unpack( 'H*', substr( $tags->{APIC}->[3], 45982, 2 ) ), 'ffd9', 'v2.4 APIC unsync JPEG end data ok' );
}

# v2.4 with empty text frame, a bug would insert the text from the previous frame
{
    my $s = Audio::Scan->scan( _f('v2.4-empty-text.mp3') );
    my $tags = $s->{tags};
    
    ok ( !exists $tags->{TPE3}, 'v2.4 empty text TPE3 frame not present' );
    is( $tags->{CATALOGNUMBER}, 'DUKE149D', 'v2.4 empty text next frame ok' );
}

# Bug 15992, v2.3 + v1.1 + APEv2 + Lyricsv2
{
    my $s = Audio::Scan->scan( _f('v2.3-apev2-lyricsv2.mp3') );
    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0, ID3v1.1', 'v2.3 APEv2+Lyricsv2 id3_version ok' );
    is( $info->{ape_version}, 'APEv2', 'v2.3 APEv2+Lyricsv2 ape_version ok' );
    is( $tags->{TIT2}, 'Fifteen Floors', 'v2.3 APEv2+Lyricsv2 TIT2 ok' );
    is( $tags->{REPLAYGAIN_TRACK_PEAK}, '1.077664', 'v2.3 APEv2+Lyricsv2 REPLAYGAIN_TRACK_PEAK ok' );
}

# Bug 16056, v2.4 + APEv2 with invalid key
{
    # Hide stderr
    no strict 'subs';
    no warnings;
    open OLD_STDERR, '>&', STDERR;
    close STDERR;
    
    my $s = Audio::Scan->scan( _f('v2.4-ape-invalid-key.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{REPLAYGAIN_ALBUM_GAIN}, '-1.720000 dB', 'v2.4 APE invalid key tag read ok' );
    
    # Restore stderr
    open STDERR, '>&', OLD_STDERR;
}

# Bug 16073, zero-byte frames
{
    my $s = Audio::Scan->scan( _f('v2.3-zero-frame.mp3') );
    my $tags = $s->{tags};
    
    ok( !exists $tags->{WCOM}, 'v2.3 zero-frame WCOM not present ok' );
    is( $tags->{TDRC}, 1982, 'v2.3 zero-frame TDRC ok' );
}

# Bug 16079, TCON with BOM but no text
{
    my $s = Audio::Scan->scan( _f('v2.3-empty-tcon2.mp3') );
    my $tags = $s->{tags};
    
    ok( !exists $tags->{TCON}, 'v2.3 empty TCON not present ok' );
    is( $tags->{TALB}, 'Unbekanntes Album', 'v2.3 empty TCON TALB ok' );
}

# RT 57664, invalid AENC tag
{
    my $s = Audio::Scan->scan( _f('v2.3-invalid-aenc.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TALB}, 'Pure Atmosphere', 'v2.3 invalid AENC TALB ok' );
    is( length($tags->{TPE4}), 26939, 'v2.3 invalid AENC TPE4 ok' );
    is( length($tags->{AENC}->[0]), 10600, 'v2.3 invalid AENC AENC ok' );
}

# Invalid RVAD tag
{
    my $s = Audio::Scan->scan( _f('v2.3-invalid-rvad.mp3') );
    my $tags = $s->{tags};
    
    ok( !$tags->{RVAD}, 'v2.3 invalid RVAD skipped ok' );
    is( $tags->{TBPM}, 125, 'v2.3 invalid RVAD frame after RVAD ok' );
}

# Bug 15992 again, APE tag wasn't read properly
{
    my $s = Audio::Scan->scan( _f('ape-v1.mp3') );
    my $tags = $s->{tags};
    
    is( $tags->{TPE1}, 'Blue', 'APEv2/ID3v1 TPE1 ok' );
    is( $tags->{REPLAYGAIN_ALBUM_GAIN}, '-9.240000 dB', 'APEv2/ID3v1 REPLAYGAIN_ALBUM_GAIN ok' );
}

# Bug 16452, v2.2 with multiple TT2/TP1 that are empty null bytes
{
    my $s = Audio::Scan->scan( _f('v2.2-multiple-null-strings.mp3') );
    my $tags = $s->{tags};
    
    ok( !ref $tags->{TIT2}, 'v2.2 multiple null strings in TT2 ok' );
    ok( !ref $tags->{TPE1}, 'v2.2 multiple null strings in TP1 ok' );
    is( $tags->{TIT2}, 'Klangstudie II', 'v2.2 multiple null strings TT2 value ok' );
    is( $tags->{TPE1}, 'Herbert Eimert', 'v2.2 multiple null strings TP1 value ok' );
}

# Bad first samplerate (stream from Radio Paradise)
{
    my $s = Audio::Scan->scan( _f('bad-first-samplerate.mp3') );
    my $info = $s->{info};
    
    is( $info->{samplerate}, 44100, 'Bad first samplerate detected as 44100 ok' );
}

# File with Xing tag but no LAME data, used to not include info->{vbr}
{
    my $s = Audio::Scan->scan( _f('v2.3-xing-no-lame.mp3') );
    my $info = $s->{info};
    
    is( $info->{vbr}, 1, 'Xing without LAME marked as VBR ok' );
}

# File with extended header bit set but no extended header
{
    warning_like { Audio::Scan->scan( _f('v2.3-ext-header-invalid.mp3') ); }
        [ qr/Error: Invalid ID3 extended header size/ ],
        'v2.3 invalid extended header ok';
}

# Bug 15895, bad APE tag
{
    my $s;
    warning_like { $s = Audio::Scan->scan( _f('v2.3-ape-bug15895.mp3') ); }
        [ qr/Ran out of tag data before number of items was reached/ ],
        'broken APE tag (bug 15895) ok';
    
    my $tags = $s->{tags};
    
    is( $tags->{TALB}, 'Laundry Service', 'bad APE tag ID3 TALB ok' );
    is( $tags->{MP3GAIN_MINMAX}, '123,203', 'bad APE tag MP3GAIN_MINMAX ok' );
}

sub _f {    
    return catfile( $FindBin::Bin, 'mp3', shift );
}
