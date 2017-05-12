use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 71;

use Audio::Scan;

# File with metadata only, no audio frames
{
    my $s = Audio::Scan->scan( _f('md5.flac') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 5581, 'Audio offset ok' );
    is( $info->{bitrate}, 0, 'Bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'Bits per sample ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{file_size}, 5581, 'File size ok' );
    is( $info->{maximum_blocksize}, 4096, 'Max blocksize ok' );
    is( $info->{maximum_framesize}, 11535, 'Max framesize ok' );
    is( $info->{audio_md5}, '00428198e1ae27ad16754f75ff068752', 'MD5 ok' );
    is( $info->{minimum_blocksize}, 4096, 'Min blocksize ok' );
    is( $info->{minimum_framesize}, 16, 'Min framesize ok' );
    is( $info->{samplerate}, 44100, 'Samplerate ok' );
    is( $info->{song_length_ms}, 626466, 'Song length ok' );
    is( $info->{total_samples}, 27627180, 'Total samples ok' );
    
    is( $tags->{VENDOR}, 'reference libFLAC 1.1.4 20070213', 'VENDOR ok' );
    is( $tags->{TITLE}, 'IV. Allegro impetuoso ', 'TITLE ok' );
}

# Application block, cue sheet
{
    my $s = Audio::Scan->scan( _f('appId.flac') );

    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{bitrate}, 187, 'Bitrate ok' );
    
    is( ref $tags->{APPLICATION}, 'HASH', 'Application ok' );
    like( $tags->{APPLICATION}->{1835361648}, qr/^<\?xml/, 'App block start ok' );
    like( $tags->{APPLICATION}->{1835361648}, qr{</rdf:RDF>\n}, 'App block end ok' );

    is( ref $tags->{CUESHEET_BLOCK}, 'ARRAY', 'Cue sheet ok' );
    is( scalar @{ $tags->{CUESHEET_BLOCK} }, 37, 'Cue sheet size ok' );
    
    my $cue = $tags->{CUESHEET_BLOCK};
    like( $cue->[0], qr/FILE "[^"]+" FLAC\n/, 'Cue 0 ok' );
    is( $cue->[1],  "  TRACK 01 AUDIO\n", 'Cue track 1 ok' );
    is( $cue->[2],  "    FLAGS PRE\n", 'Cue track 1 pre ok' );
    is( $cue->[3],  "    ISRC 123456789012\n", 'Cue track 1 ISRC ok' );
    is( $cue->[4],  "    INDEX 00 00:00:00\n", 'Cue track 1 index 0 ok' );
    is( $cue->[5],  "    INDEX 01 00:00:32\n", 'Cue track 1 index 1 ok' );
    is( $cue->[6],  "  TRACK 02 AUDIO\n", 'Cue track 2 ok' );
    is( $cue->[7],  "    INDEX 01 04:53:72\n", 'Cue track 2 index 1 ok' );
    
    is( $cue->[32], "  TRACK 14 AUDIO\n", 'Cue track 14 ok' );
    is( $cue->[33], "    INDEX 00 56:03:70\n", 'Cue track 14 index 0 ok' );
    is( $cue->[34], "    INDEX 01 56:07:45\n", 'Cue track 14 index 1 ok' );
    is( $cue->[35], "REM FLAC__lead-in 88200\n", 'Cue lead-in ok' );
    is( $cue->[36], "REM FLAC__lead-out 170 34042260\n", 'Cue lead-out ok' );
}

# FLAC file with ID3 tag
{
    my $s = Audio::Scan->scan( _f('id3tagged.flac'), { md5_size => 4096 } );

    my $info = $s->{info};
    my $tags = $s->{tags};
    
    is( $info->{id3_version}, 'ID3v2.3.0', 'ID3 tag ok' );
    is( $info->{audio_offset}, 10034, 'ID3 tag audio offset ok' );
    is( $info->{audio_size}, 19966, 'Audio size ok' );
    is( $info->{audio_md5}, '3a15e851a1dad49adcca57fe40ef6df6', 'Audio MD5 ok' );
    
    is( $tags->{TITLE}, 'Allegro Maestoso', 'ID3 tag Vorbis title ok' );
    is( $tags->{TIT2}, 'Allegro Maestoso', 'ID3 tag TIT2 ok' );
}

# FLAC file with picture
{
    my $s = Audio::Scan->scan( _f('picture.flac') );

    my $tags = $s->{tags};
    
    is( ref $tags->{ALLPICTURES}, 'ARRAY', 'ALLPICTURES ok' );
    is( scalar @{ $tags->{ALLPICTURES} }, 1, 'ALLPICTURES count ok' );
    
    my $pic = $tags->{ALLPICTURES}->[0];
    
    is( ref $pic, 'HASH', 'Picture 0 ok' );
    is( $pic->{color_index}, 0, 'Color index ok' );
    is( $pic->{depth}, 24, 'Depth ok' );
    is( $pic->{description}, '', 'Description ok' );
    is( $pic->{height}, 300, 'Height ok' );
    is( length( $pic->{image_data} ), 37175, 'Image data ok' );
    is( unpack( 'H*', substr( $pic->{image_data}, 0, 4 ) ), 'ffd8ffe0', 'JPEG data ok ');
    is( $pic->{mime_type}, 'image/jpeg', 'MIME type ok' );
    is( $pic->{picture_type}, 3, 'Picture type ok' );
    is( $pic->{width}, 301, 'Width ok' );
}

# Test ignoring artwork
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    
    my $s = Audio::Scan->scan( _f('picture.flac') );
    
    my $tags = $s->{tags};
    
    my $pic = $tags->{ALLPICTURES}->[0];
    
    is( $pic->{image_data}, 37175, 'JPEG with AUDIO_SCAN_NO_ARTWORK ok ');
    is( $pic->{offset}, 686, 'JPEG with AUDIO_SCAN_NO_ARTWORK offset ok' );
}

# File with very short duration, make sure bitrate is correct
{
    my $s = Audio::Scan->scan( _f('short-duration.flac') );
    
    my $info = $s->{info};
    
    is( $info->{audio_offset}, 8304, 'Short duration audio offset ok' );
    is( $info->{bitrate}, 946303, 'Short duration bitrate ok' );
}

# Find frame, seektable available
{
    my $offset = Audio::Scan->find_frame( _f('tiny.flac'), 500 );
    is( $offset, 50005, 'Find frame with seektable ok' );
}

# Find frame near the end
{
    my $offset = Audio::Scan->find_frame( _f('tiny.flac'), 1000 );
    is( $offset, 80872, 'Find frame near end with seektable ok' );
}

# Find frame in corrupted file
{
    my $offset = Audio::Scan->find_frame( _f('appId.flac'), 10 );
    is( $offset, 8011, 'Find frame in corrupted stream ok' );
}

# Find frame in file with ID3
{
    my $offset = Audio::Scan->find_frame( _f('id3tagged.flac'), 2000 );
    is( $offset, 12792, 'Find frame in ID3-tagged file ok' );
}

# Find frame in file with ID3 using filehandle
{
    open my $fh, '<', _f('id3tagged.flac');
    my $offset = Audio::Scan->find_frame_fh( flac => $fh, 2000 );
    close $fh;
    
    is( $offset, 12792, 'Find frame via filehandle in ID3-tagged file ok' );
}

{
    open my $fh, '<', _f('tiny.flac');
    my $offset = Audio::Scan->find_frame_fh( flac => $fh, 500 );
    close $fh;

    is( $offset, 50005, 'Find frame via filehandle ok' );
}

# Find frame in file with picture tag
{
    my $offset = Audio::Scan->find_frame( _f('picture-large.flac'), 1000 );
    is( $offset, 337723, 'Find frame in picture file ok' );
}

# Calc duration/bitrate when missing header information
{
    my $s = Audio::Scan->scan( _f('bad-streaminfo.flac') );
    
    my $info = $s->{info};
    is( $info->{audio_offset}, 350, 'Bad streaminfo audio offset ok' );
    is( $info->{bitrate}, 268415, 'Bad streaminfo bitrate ok' );
    is( $info->{maximum_framesize}, 0, 'Bad streaminfo has no max framesize' );
    is( $info->{audio_md5}, '0' x 32, 'Bad streaminfo has no md5' );
    is( $info->{minimum_framesize}, 0, 'Bad streaminfo has no min framesize' );
    
    # XXX These values are slightly short because we aren't reading
    # backwards from the end to find the actual last frame
    is( $info->{song_length_ms}, 1462, 'Bad streaminfo duration ok' );
    is( $info->{total_samples}, 64512, 'Bad streaminfo total_samples ok' );
}

# Invalid comment length
{
    my $s = Audio::Scan->scan( _f('CVE-2007-4619-2.flac') );
    my $tags = $s->{tags};
    
    is( $tags->{ALBUM}, 'Quod Libet Test Data', 'CVE-2007-4619 handled ok' );
}    

sub _f {
    return catfile( $FindBin::Bin, 'flac', shift );
}
