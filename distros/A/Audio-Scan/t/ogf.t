use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 45;

use Audio::Scan;

my $HAS_ENCODE;
eval {
    require Encode;
    $HAS_ENCODE = 1;
};

# Basics
{
    my $s = Audio::Scan->scan( _f('test.ogf') );

    my $info = $s->{info};
    my $tags = $s->{tags};

    is( $info->{audio_offset}, 8498, 'Audio offset ok' );
    is( $info->{bitrate}, 215793, 'Bitrate ok' );
    is( $info->{bits_per_sample}, 16, 'Bits per sample ok' );
    is( $info->{channels}, 2, 'Channels ok' );
    is( $info->{file_size}, 52358, 'File size ok' );
    is( $info->{maximum_blocksize}, 4096, 'Max blocksize ok' );
    is( $info->{maximum_framesize}, 2501, 'Max framesize ok' );
    is( $info->{audio_md5}, 'b8b878af74e8401474ef7754aaedac47', 'MD5 ok' );
    is( $info->{minimum_blocksize}, 4096, 'Min blocksize ok' );
    is( $info->{minimum_framesize}, 1414, 'Min framesize ok' );
    is( $info->{samplerate}, 44100, 'Samplerate ok' );
    is( $info->{song_length_ms}, 1626, 'Song length ok' );
    is( $info->{total_samples}, 71748, 'Total samples ok' );

    is( $tags->{VENDOR}, 'reference libFLAC 1.3.4 20220220', 'VENDOR ok' );
    is( $tags->{GENRE}, 'Electronic', 'TITLE ok' );
	is( $tags->{ALBUM}, 'Mutant Funk', 'ALBUM ok' );
}

# Test METADATA_BLOCK_PICTURE
{
    my $s = Audio::Scan->scan( _f('picture.ogf') );
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

# Test scan get info on large vorbis comment and 0 offset
{
	open my $fh, '<', _f('large-comment.ogf');
	binmode $fh;
	my $info = Audio::Scan->find_frame_fh_return_info( ogf => $fh, 0 );
	
	is( $info->{audio_offset}, 106744, 'Audio offset ok' );
	is( $info->{seek_offset}, 106744, 'Seek offset ok' );
	is( length $info->{seek_header}, 98411, 'Seek header ok' );
}

# Test scan get info on large vorbis comment and 500 ms offset
{
	open my $fh, '<', _f('large-comment.ogf');
	binmode $fh;
	my $info = Audio::Scan->find_frame_fh_return_info( ogf => $fh, 500 );
	
	is( $info->{audio_offset}, 106744, 'Audio offset ok' );
	is( $info->{seek_offset}, 193419, 'Seek offset ok' );
	is( length $info->{seek_header}, 98411, 'Seek header ok' );
	
	close $fh;
	
	open $fh, '>', _f('headers.ogf');
	binmode $fh;
	print $fh $info->{seek_header};
	close $fh;
	
	my $s = Audio::Scan->scan( _f('headers.ogf') );
	my $info = $s->{info};
 	my $tags = $s->{tags};
	
	is( $info->{bits_per_sample}, 16, 'Bits per sample ok' );
	is( $info->{channels}, 2, 'Channels ok' );
	is( $info->{maximum_blocksize}, 4096, 'Max blocksize ok' );
	is( $info->{maximum_framesize}, 16394, 'Max framesize ok' );
	is( $info->{audio_md5}, '00000000000000000000000000000000', 'MD5 ok' );
	is( $info->{minimum_blocksize}, 4096, 'Min blocksize ok' );
	is( $info->{minimum_framesize}, 12572, 'Min framesize ok' );
	is( $info->{samplerate}, 44100, 'Samplerate ok' );
	is( $info->{song_length_ms}, 0, 'Song length ok' );
	is( $info->{total_samples}, 0, 'Total samples ok' );

	is( $tags->{VENDOR}, 'reference libFLAC 1.2.1 20070917', 'VENDOR ok' );

	unlink _f('headers.ogf');
	
}

sub _f {
    return catfile( $FindBin::Bin, 'ogf', shift );
}
