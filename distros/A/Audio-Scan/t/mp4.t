use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 120;

use Audio::Scan;

# TODO: DLNA profile tests:
#  AAC_ISO
#  AAC_MULT5_ISO
#  AAC_LTP_ISO
#  AAC_LTP_MULT5_ISO
#  AAC_LTP_MULT7_ISO
#  HEAAC_L2_ISO_128
#  HEAAC_L2_ISO_320
#  HEAAC_L2_ISO
#  HEAAC_MULT5_ISO
#  HEAAC_MULT7
#  HEAACv2_L2_128
#  HEAACv2_L2_320
#  HEAACv2_L3
#  HEAACv2_L4
#  HEAACv2_MULT5
#  HEAACv2_MULT7

# Failing profiles:
#   O-HEAAC_ISO_128-stereo-16kHz-12.mp4 (channels 1, should be 2)

# AAC file from iTunes 8.1.1
{
    my $s = Audio::Scan->scan( _f('itunes811.m4a'), { md5_size => 4096 } );
    
    my $info  = $s->{info};
    my $tags  = $s->{tags};
    my $track = $info->{tracks}->[0];
    
    is( $info->{audio_offset}, 6169, 'Audio offset ok' );
    is( $info->{audio_size}, 320, 'Audio size ok' );
    is( $info->{audio_md5}, '9bf0388a5bfd81c857fdce52dac9ce7f', 'Audio MD5 ok' );
    is( $info->{compatible_brands}->[0], 'M4A ', 'Compatible brand 1 ok' );
    is( $info->{compatible_brands}->[1], 'mp42', 'Compatible brand 2 ok' );
    is( $info->{compatible_brands}->[2], 'isom', 'Compatible brand 3 ok' );
    is( $info->{leading_mdat}, undef, 'Leading MDAT flag is blank' );
    is( $info->{file_size}, 6489, 'File size ok' );
    is( $info->{major_brand}, 'M4A ', 'Major brand ok' );
    is( $info->{minor_version}, 0, 'Minor version ok' );
    is( $info->{song_length_ms}, 69, 'Song length ok' );
    is( $info->{samplerate}, 44100, 'Sample rate ok' );
    is( $info->{avg_bitrate}, 96000, 'Avg bitrate ok' );
    is( $info->{dlna_profile}, 'AAC_ISO_192', 'DLNA profile AAC_ISO_192 ok' );
    
    is( $track->{audio_object_type}, 2, 'Audio object type ok' );
    is( $track->{audio_type}, 64, 'Audio type ok' );
    is( $track->{bits_per_sample}, 16, 'Bits per sample ok' );
    is( $track->{channels}, 2, 'Channels ok' );
    is( $track->{duration}, 69, 'Duration ok' );
    is( $track->{encoding}, 'mp4a', 'Encoding ok' );
    is( $track->{handler_name}, '', 'Handler name ok' );
    is( $track->{handler_type}, 'soun', 'Handler type ok' );
    is( $track->{id}, 1, 'Track ID ok' );
    is( $track->{max_bitrate}, 0, 'Max bitrate ok' );
    
    is( $tags->{AART}, 'Album Artist', 'AART ok' );
    is( $tags->{ALB}, 'Album', 'ALB ok' );
    is( $tags->{ART}, 'Artist', 'ART ok' );
    is( $tags->{CMT}, 'Comments', 'CMT ok' );
    is( length($tags->{COVR}), 2103, 'COVR ok' );
    is( $tags->{CPIL}, 1, 'CPIL ok' );
    is( $tags->{DAY}, 2009, 'DAY ok' );
    is( $tags->{DESC}, 'Video Description', 'DESC ok' );
    is( $tags->{DISK}, '1/2', 'DISK ok' );
    is( $tags->{GNRE}, 'Jazz', 'GNRE ok' );
    is( $tags->{GRP}, 'Grouping', 'GRP ok' );
    is( $tags->{ITUNNORM}, ' 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000', 'ITUNNORM ok' );
    is( $tags->{ITUNSMPB}, ' 00000000 00000840 000001E4 00000000000001DC 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000', 'ITUNSMPB ok' );
    is( $tags->{LYR}, 'Lyrics', 'LYR ok' );
    is( $tags->{NAM}, 'Name', 'NAM ok' );
    is( $tags->{PGAP}, 1, 'PGAP ok' );
    is( $tags->{SOAA}, 'Sort Album Artist', 'SOAA ok' );
    is( $tags->{SOAL}, 'Sort Album', 'SOAL ok' );
    is( $tags->{SOAR}, 'Sort Artist', 'SOAR ok' );
    is( $tags->{SOCO}, 'Sort Composer', 'SOCO ok' );
    is( $tags->{SONM}, 'Sort Name', 'SONM ok' );
    is( $tags->{SOSN}, 'Sort Show', 'SOSN ok' );
    is( $tags->{TMPO}, 120, 'TMPO ok' );
    is( $tags->{TOO}, 'iTunes 8.1.1, QuickTime 7.6', 'TOO ok' );
    is( $tags->{TRKN}, '1/10', 'TRKN ok' );
    is( $tags->{TVEN}, 'Episode ID', 'TVEN ok' );
    is( $tags->{TVES}, 12, 'TVES ok' );
    is( $tags->{TVSH}, 'Show', 'TVSH ok' );
    is( $tags->{TVSN}, 12, 'TVSN ok' );
    is( $tags->{WRT}, 'Composer', 'WRT ok' );
}

# ALAC file from iTunes 8.1.1
{
    my $s = Audio::Scan->scan( _f('alac.m4a') );
    
    my $info  = $s->{info};
    my $tags  = $s->{tags};
    my $track = $info->{tracks}->[0];
    
    is( $info->{audio_offset}, 3850, 'ALAC audio offset ok' );
    is( $info->{song_length_ms}, 10, 'ALAC song length ok' );
    is( $info->{samplerate}, 44100, 'ALAC samplerate ok' );
    is( $info->{avg_bitrate}, 981600, 'ALAC avg bitrate ok' );
    ok( !exists $info->{dlna_profile}, 'ALAC no DLNA profile ok' );
    
    is( $track->{duration}, 10, 'ALAC duration ok' );
    is( $track->{encoding}, 'alac', 'ALAC encoding ok' );
    is( $track->{bits_per_sample}, 16, 'ALAC bits_per_sample ok' );
    is( $track->{channels}, 2, 'ALAC channels ok' );
    
    is( $tags->{CPIL}, 0, 'ALAC CPIL ok' );
    is( $tags->{DISK}, '1/2', 'ALAC DISK ok' );
    is( $tags->{TOO}, 'iTunes 8.1.1', 'ALAC TOO ok' );
}

# File with mdat before the rest of the boxes
{
    my $s = Audio::Scan->scan( _f('leading-mdat.m4a') );
    
    my $info  = $s->{info};
    my $tags  = $s->{tags};
    
    is( $info->{audio_offset}, 20, 'Leading MDAT offset ok' );
    is( $info->{leading_mdat}, 1, 'Leading MDAT flag ok' );
    is( $info->{song_length_ms}, 69845, 'Leading MDAT length ok' );
    is( $info->{samplerate}, 44100, 'Leading MDAT samplerate ok' );
    is( $info->{avg_bitrate}, 128000, 'Leading MDAT bitrate ok' );
    ok( !exists $info->{dlna_profile}, 'Leading MDAT no DLNA profile ok' );
    
    is( $tags->{DAY}, '-001', 'Leading MDAT DAY ok' );
    is( $tags->{TOO}, 'avc2.0.11.1110', 'Leading MDAT TOO ok' );
}

# File with array keys, bug 13486
{
    my $s = Audio::Scan->scan( _f('array-keys.m4a') );
    
    my $tags = $s->{tags};
    
    is( $tags->{AART}, 'Sonic Youth', 'Array key single key ok' );
    is( ref $tags->{PRODUCER}, 'ARRAY', 'Array key array element ok' );
    is( $tags->{PRODUCER}->[0], 'Ron Saint Germain', 'Array key element 0 ok' );
    is( $tags->{PRODUCER}->[1], 'Nick Sansano', 'Array key element 1 ok' );
    is( $tags->{PRODUCER}->[2], 'Sonic Youth', 'Array key element 2 ok' );
    is( $tags->{PRODUCER}->[3], 'J Mascis', 'Array key element 3 ok' );
    is( $tags->{PRODUCER}->[4], 'Don Fleming', 'Array key element 4 ok' );
}

# 88.2 kHz sample rate, bug 8563
{
    my $s = Audio::Scan->scan( _f('882-sample-rate.m4a') );
    
    my $info = $s->{info};
    
    is( $info->{samplerate}, 88200, '88.2 sample rate ok' );
    is( $info->{song_length_ms}, 179006, '88.2 song length ok' );
    ok( !exists $info->{dlna_profile}, '88.2 no DLNA profile ok' );
}

# Multiple covers, bug 14476
{
	my $s = Audio::Scan->scan( _f('multiple-covers.m4a') );
	
	my $tags = $s->{tags};
	
	is( length( $tags->{COVR} ), 2103, 'Multiple cover art reads first cover ok' );
}

# Test ignoring artwork
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    
    my $s = Audio::Scan->scan( _f('multiple-covers.m4a') );
	
	my $tags = $s->{tags};
	
	is( $tags->{COVR}, 2103, 'COVR with AUDIO_SCAN_NO_ARTWORK ok' );
	is( $tags->{COVR_offset}, 1926, 'COVR with AUDIO_SCAN_NO_ARTWORK offset ok' );
}

# File with array keys that are integers, bug 14462
{
    my $s = Audio::Scan->scan( _f('array-keys-int.m4a') );
    
    my $tags = $s->{tags};
    
    is( $tags->{AART}, 'Stevie Wonder', 'Array key int single key ok' );
    is( ref $tags->{FREE}, 'ARRAY', 'Array key int array element ok' );
    is( $tags->{FREE}->[0], 1969970, 'Array key int element 0 ok' );
    is( $tags->{FREE}->[1], 'xxxxxx@xxxxxx.com', 'Array key int element 1 ok' );
    is( $tags->{FREE}->[2], 46726, 'Array key int element 2 ok' );
    is( $tags->{FREE}->[3], 1969972, 'Array key int element 3 ok' );
    is( $tags->{FREE}->[4], 15, 'Array key int element 4 ok' );
    is( $tags->{FREE}->[5], 0, 'Array key int element 5 ok' );
}

# File with short trkn field
{
    my $s = Audio::Scan->scan( _f('short-trkn.m4a') );
    
    my $tags = $s->{tags};
    
    is( $tags->{TRKN}, 10, 'Short trkn ok' );
}

# HD-AAC file
# Contains 48khz LC track and 96khz SLS track
{
    my $s = Audio::Scan->scan( _f('hd-aac.m4a') );
    
    my $info = $s->{info};
    
    is( $info->{samplerate}, 96000, 'HD-AAC samplerate ok' );
    is( $info->{song_length_ms}, 409130, 'HD-AAC song length ok' );
    is( $info->{avg_bitrate}, 4, 'HD-AAC avg bitrate ok' );
    ok( !exists $info->{dlna_profile}, 'HD-AAC no DLNA profile ok' );
    
    my $track1 = $info->{tracks}->[0];
    my $track2 = $info->{tracks}->[1];
    
    is( $track1->{audio_object_type}, 2, 'HD-AAC LC track ok' );
    is( $track1->{samplerate}, 48000, 'HD-AAC LC track samplerate ok' );
    is( $track1->{bits_per_sample}, 16, 'HD-AAC LC track bps ok' );
    
    is( $track2->{audio_object_type}, 37, 'HD-AAC SLS track ok' );
    is( $track2->{samplerate}, 96000, 'HD-AAC SLS track samplerate ok' );
    is( $track2->{bits_per_sample}, 24, 'HD-AAC SLS track bps ok' );
}

# Bug 15262, secondary hint track with 0 duration, caused bad song_length_ms value
{
    my $s = Audio::Scan->scan( _f('hint-track.m4a') );
    
    my $info = $s->{info};
    
    is( $info->{song_length_ms}, 263433, 'MP4 hint track song_length_ms ok' );
    is( $info->{dlna_profile}, 'AAC_ISO_320', 'MP4 hint track DLNA profile AAC_ISO_320 ok' );
    is( $info->{tracks}->[0]->{duration}, 263433, 'MP4 hint track track 1 duration ok' );
    is( $info->{tracks}->[1]->{duration}, 0, 'MP4 hint track track 2 duration ok' );
}

# HE-AAC file, tests that we got the right samplerate from esds
{
    my $s = Audio::Scan->scan( _f('heaac.mp4') );
    
    my $info = $s->{info};
    
    is( $info->{samplerate}, 16000, 'HE-AAC main samplerate 16000 ok' );
    is( $info->{tracks}->[0]->{samplerate}, 16000, 'HE-AAC track 1 samplerate 16000 ok' );
    
    # XXX this should be 2
    #is( $info->{tracks}->[0]->{channels}, 2, 'HE-AAC track 1 channels 2 ok' );
}

# Find frame
{
    my $offset = Audio::Scan->find_frame( _f('itunes811.m4a'), 30 );
    
    is( $offset, 6183, 'Find frame ok' );
}

# Find frame with info
{
    my $info = Audio::Scan->find_frame_return_info( _f('itunes811.m4a'), 30 );
    
    is( $info->{seek_offset}, 6183, 'Find frame return info offset ok' );
    is( length( $info->{seek_header} ), 6173, 'Find frame return info header rewrite ok' );
}

# Find frame in ALAC file with unusual stts values
{
    my $info = Audio::Scan->find_frame_return_info( _f('alac-multiple-stts.m4a'), 30000 );
    
    is( $info->{seek_offset}, 2123193, 'Find frame in ALAC multiple stts ok' );
    is( length( $info->{seek_header} ), 34274, 'Find frame in ALAC multiple stts header ok' );
}

# Find frame in HD-AAC file (2 tracks) (not yet supported)
{
    my $info = Audio::Scan->find_frame_return_info( _f('hd-aac.m4a'), 10 );
    
    is( $info->{seek_offset}, -1, 'Find frame in HD-AAC ok' );
}

# Find frame with info from filehandle
{
    open my $fh, '<', _f('itunes811.m4a');
    
    my $info = Audio::Scan->find_frame_fh_return_info( mp4 => $fh, 30 );
    
    is( $info->{seek_offset}, 6183, 'Find frame return info via filehandle ok' );
    is( length( $info->{seek_header} ), 6173, 'Find frame return info via filehandle rewrite ok' );
    
    close $fh;
}

sub _f {
    return catfile( $FindBin::Bin, 'mp4', shift );
}