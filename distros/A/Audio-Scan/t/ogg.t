use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 72;

use Audio::Scan;

my $HAS_ENCODE;
eval {
    require Encode;
    $HAS_ENCODE = 1;
};

# Basics
{
    my $s = Audio::Scan->scan( _f('test.ogg'), { md5_size => 4096 } );

    my $info = $s->{info};
    my $tags = $s->{tags};

    SKIP:
    {
        skip 'Encode is not available', 1 unless $HAS_ENCODE;
        my $utf8 = Encode::decode_utf8('シチヅヲ');
        is($tags->{PERFORMER}, $utf8, 'PERFORMER (UTF8) Tag ok');
    }

    is($tags->{ARTIST}, 'Test Artist', 'ASCII Tag ok');
    is($tags->{YEAR}, 2009, 'Year Tag ok');
    ok($tags->{VENDOR} =~ /Xiph/, 'Vendor ok');

    is($info->{bitrate_average}, 757, 'Bitrate ok');
    is($info->{channels}, 2, 'Channels ok');
    is($info->{file_size}, 4553, 'File size ok' );
    is($info->{stereo}, 1, 'Stereo ok');
    is($info->{samplerate}, 44100, 'Sample Rate ok');
    is($info->{song_length_ms}, 3684, 'Song length ok');
    is($info->{audio_offset}, 4204, 'Audio offset ok');
    is($info->{audio_size}, 349, 'Audio size ok');
    is($info->{audio_md5}, '9b38152aacb22c128375274add565f99', 'Audio MD5 ok' );
}

# Multiple tags.
{
    my $s = Audio::Scan->scan( _f('multiple.ogg') );

    my $tags = $s->{tags};

    is($tags->{ARTIST}[0], 'Multi 1', 'Multiple Artist 1 ok');
    is($tags->{ARTIST}[1], 'Multi 2', 'Multiple Artist 1 ok');
    is($tags->{ARTIST}[2], 'Multi 3', 'Multiple Artist 1 ok');
}

# Equals char in tag.
{
    my $s = Audio::Scan->scan( _f('equals-char.ogg') );

    my $tags = $s->{tags};

    is($tags->{TITLE}, 'Me - You = Loneliness', 'Equals char in tag ok');
}

# Large page size.
{
    my $s = Audio::Scan->scan( _f('large-pagesize.ogg') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is($info->{audio_offset}, 110616, 'Large page size audio offset ok');
    is($tags->{TITLE}, 'Deadzy', 'Large page title tag ok');
    is($tags->{ARTIST}, 'Medeski Scofield Martin & Wood', 'Large page artist tag ok');
    is($tags->{ALBUM}, 'Out Louder (bonus disc)', 'Large page album tag ok');
}

# Test COVERART
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

    my $s = Audio::Scan->scan( _f('large-pagesize.ogg') );

    my $tags = $s->{tags};
    my $pic = $tags->{ALLPICTURES}->[0];

    is( $pic->{color_index}, 0, 'COVERART color_index ok' );
    is( $pic->{depth}, 0, 'COVERART depth ok' );
    is( $pic->{description}, '', 'COVERART description ok' );
    is( $pic->{height}, 0, 'COVERART height ok' );
    is( $pic->{image_data}, 104704, 'COVERART length ok' ); # this is the base64-encoded length
    is( $pic->{mime_type}, 'image/', 'COVERART mime_type ok' );
    is( $pic->{picture_type}, 0, 'COVERART picture_type ok' );
    is( $pic->{width}, 0, 'COVERART width ok' );
}

# Test COVERART data
{
    my $s = Audio::Scan->scan( _f('large-pagesize.ogg') );

    my $tags = $s->{tags};
    my $pic = $tags->{ALLPICTURES}->[0];

    is( length( $pic->{image_data} ), 78527, 'COVERART real length ok' ); # without base64 encoding
    is( unpack( 'H*', substr( $pic->{image_data}, 0, 4 ) ), 'ffd8ffe0', 'COVERART JPEG picture data ok ');
}

# Test METADATA_BLOCK_PICTURE
{
    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

    my $s = Audio::Scan->scan( _f('metadata-block-picture.ogg') );

    my $tags = $s->{tags};
    my $pic  = $tags->{ALLPICTURES}->[0];
    my $pic2 = $tags->{ALLPICTURES}->[1];

    is( $pic->{color_index}, 0, 'METADATA_BLOCK_PICTURE color_index ok' );
    is( $pic->{depth}, 0, 'METADATA_BLOCK_PICTURE depth ok' );
    is( $pic->{description}, '', 'METADATA_BLOCK_PICTURE description ok' );
    is( $pic->{height}, 0, 'METADATA_BLOCK_PICTURE height ok' );
    is( $pic->{image_data}, 25078, 'METADATA_BLOCK_PICTURE length ok' );
    is( $pic->{mime_type}, 'image/jpeg', 'METADATA_BLOCK_PICTURE mime_type ok' );
    is( $pic->{picture_type}, 3, 'METADATA_BLOCK_PICTURE picture_type ok' );
    is( $pic->{width}, 0, 'METADATA_BLOCK_PICTURE width ok' );

    is( $pic2->{image_data}, 1761, 'METADATA_BLOCK_PICTURE pic2 length ok' );
}

# Test METADATA_BLOCK_PICTURE data
{
    my $s = Audio::Scan->scan( _f('metadata-block-picture.ogg') );

    my $tags = $s->{tags};
    my $pic  = $tags->{ALLPICTURES}->[0];
    my $pic2 = $tags->{ALLPICTURES}->[1];

    is( length( $pic->{image_data} ), 25078, 'METADATA_BLOCK_PICTURE real length ok' );
    is( unpack( 'H*', substr( $pic->{image_data}, 0, 4 ) ), 'ffd8ffe0', 'METADATA_BLOCK_PICTURE JPEG picture data ok ');

    is( length( $pic2->{image_data} ), 1761, 'METADATA_BLOCK_PICTURE pic2 real length ok' );
    is( unpack( 'H*', substr( $pic2->{image_data}, 0, 4 ) ), 'ffd8ffe0', 'METADATA_BLOCK_PICTURE JPEG pic2 data ok ');
}

# Old encoder files.
{
    my $s1 = Audio::Scan->scan( _f('old1.ogg') );
    is($s1->{tags}->{ALBUM}, 'AutoTests', 'Old encoded album tag ok');
    is($s1->{info}->{samplerate}, 8000, 'Old encoded rate ok');

    my $s2 = Audio::Scan->scan( _f('old2.ogg') );
    is($s2->{tags}->{ALBUM}, 'AutoTests', 'Old encoded album tag ok');
    is($s2->{info}->{samplerate}, 12000, 'Old encoded rate ok');
}

# SC bugs
{
    my $s = Audio::Scan->scan( _f('bug1155-1.ogg') );

    my $info = $s->{info};

    is($info->{bitrate_nominal}, 206723, 'Bug1155 nominal bitrate ok');
    is($info->{bitrate_average}, 922, 'Bug1155 avg bitrate ok');
    is($info->{song_length_ms}, 187146, 'Bug1155 duration ok');
}

{
    my $s = Audio::Scan->scan( _f('bug1155-2.ogg') );

    my $info = $s->{info};

    is($info->{bitrate_average}, 2028, 'Bug1155-2 bitrate ok');
    is($info->{song_length_ms}, 5864, 'Bug1155-2 duration ok');
}

{
    my $s = Audio::Scan->scan( _f('bug803.ogg') );

    my $info = $s->{info};

    is($info->{bitrate_average}, 633, 'Bug803 bitrate ok');
    is($info->{song_length_ms}, 219104, 'Bug803 song length ok');
}

{
    my $s = Audio::Scan->scan( _f('bug905.ogg') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is($info->{bitrate_average}, 534, 'Bug905 bitrate ok');
    is($info->{song_length_ms}, 223484, 'Bug905 song length ok');
    is($tags->{DATE}, '08-05-1998', 'Bug905 date ok');
}

# Scan via a filehandle
{
    open my $fh, '<', _f('test.ogg');

    my $s = Audio::Scan->scan_fh( ogg => $fh );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is($tags->{ARTIST}, 'Test Artist', 'ASCII Tag ok via filehandle');
    is($tags->{YEAR}, 2009, 'Year Tag ok via filehandle');

    is($info->{bitrate_average}, 757, 'Bitrate ok via filehandle');

    close $fh;
}

# Find frame offset
{
    my $offset = Audio::Scan->find_frame( _f('normal.ogg'), 800 );

    is( $offset, 12439, 'Find frame ok' );
}

# Test special case where target sample is in the first frame
{
    my $offset = Audio::Scan->find_frame( _f('normal.ogg'), 300 );

    is( $offset, 3979, 'Find sample in first frame ok' );
}

{
    open my $fh, '<', _f('normal.ogg');

    my $offset = Audio::Scan->find_frame_fh( ogg => $fh, 600 );

    is( $offset, 8259, 'Find frame via filehandle ok' );

    close $fh;
}

# Bug 12615, aoTuV-encoded file uncovered bug in offset calculation
{
    my $s = Audio::Scan->scan( _f('bug12615-aotuv.ogg') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 3970, 'Bug 12615 aoTuV offset ok' );

    like( $tags->{VENDOR}, qr/aoTuV/, 'Bug 12615 aoTuV tags ok' );
}

# Test file with page segments > 128
{
    my $s = Audio::Scan->scan( _f('large-page-segments.ogg') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 41740, 'Large page segments audio offset ok' );
    is( $tags->{ARTIST}, 'Led Zeppelin', 'Large page segments comments ok' );
}

# Test file with multiple logical bitstreams
{
    my $s = Audio::Scan->scan( _f('multiple-bitstreams.ogg') );

    my $info = $s->{info};

    is( $info->{bitrate_average}, 128000, 'Multiple bitstreams bitrate ok' );
    is( $info->{song_length_ms}, 0, 'Multiple bitstreams length ok' );
}

# RT 118888, file with bad terminal header page was causing a crash trying to read non-existent comments
# ogginfo reports:
# WARNING: Vorbis stream 1 does not have headers correctly framed. Terminal header page contains additional packets or has non-zero granulepos
{
    my $s = Audio::Scan->scan( _f('tachos_melody.ogg') );

    my $info = $s->{info};

    is( $info->{audio_size}, 10210, 'Incorrect terminal header page audio_size ok' );
    is( $info->{song_length_ms}, 387, 'Incorrect terminal header page song_length_ms ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'ogg', shift );
}
