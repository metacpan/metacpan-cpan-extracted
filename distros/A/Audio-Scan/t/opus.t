use strict;

use File::Spec::Functions;
use FindBin ();
use Test::More tests => 74;

use Audio::Scan;

my $HAS_ENCODE;
eval {
    require Encode;
    $HAS_ENCODE = 1;
};

# Basics
{
    my $s = Audio::Scan->scan( _f('test-1-mono.opus'), { md5_size => 4096 } );

    my $info = $s->{info};

    is($info->{bitrate_average}, 30183, 'Bitrate ok');
    is($info->{channels}, 1, 'Channels ok');
    is($info->{file_size}, 4086, 'File size ok' );
    is($info->{stereo}, 0, 'Stereo ok');
    is($info->{samplerate}, 48000, 'Sample Rate ok');
    is($info->{input_samplerate}, 44100, 'Input Sample Rate ok');
    is($info->{song_length_ms}, 1044, 'Song length ok');
    is($info->{audio_offset}, 147, 'Audio offset ok');
    is($info->{audio_size}, 3939, 'Audio size ok');
    is($info->{audio_md5}, '688ac880cdc01ae5709a6fb104eddc2e', 'Audio MD5 ok' );
}

{
    my $s = Audio::Scan->scan( _f('test-2-stereo.opus'), { md5_size => 4096 } );

    my $info = $s->{info};

    is($info->{bitrate_average}, 67900, 'Bitrate ok');
    is($info->{channels}, 2, 'Channels ok');
    is($info->{file_size}, 24973, 'File size ok' );
    is($info->{stereo}, 1, 'Stereo ok');
    is($info->{samplerate}, 48000, 'Sample Rate ok');
    is($info->{input_samplerate}, 44100, 'Input Sample Rate ok');
    is($info->{song_length_ms}, 2925, 'Song length ok');
    is($info->{audio_offset}, 147, 'Audio offset ok');
    is($info->{audio_size}, 24826, 'Audio size ok');
    is($info->{audio_md5}, 'bebb6f0f0a90ce4e4e90635a3c7408d0', 'Audio MD5 ok' );
}

## A few of the official Opus test files from https://people.xiph.org/~greg/opus_testvectors/

{
  my $s = Audio::Scan->scan( _f('failure-end_gp_before_last_packet1.opus'), { md5_size => 4096 } );

  my $info = $s->{info};

  is($info->{bitrate_average}, 428183, 'Bitrate ok');
  is($info->{channels}, 1, 'Channels ok');
  is($info->{file_size}, 5996, 'File size ok' );
  is($info->{stereo}, 0, 'Stereo ok');
  is($info->{samplerate}, 48000, 'Sample Rate ok');
  is($info->{input_samplerate}, 11025, 'Input Sample Rate ok');
  is($info->{song_length_ms}, 109, 'Song length ok');
  is($info->{audio_offset}, 162, 'Audio offset ok');
  is($info->{audio_size}, 5834, 'Audio size ok');
  is($info->{audio_md5}, 'eb9191ba092ef91e45ec65356a2a6012', 'Audio MD5 ok' );
}

{
  my $s = Audio::Scan->scan( _f('broken.phobosstream.opus'), { md5_size => 4096 } );

  my $info = $s->{info};
  my $tags = $s->{tags};
  
  is($info->{bitrate_average}, 3715, 'Bitrate ok');
  is($info->{channels}, 2, 'Channels ok');
  is($info->{file_size}, 230827, 'File size ok' );
  is($info->{stereo}, 1, 'Stereo ok');
  is($info->{samplerate}, 48000, 'Sample Rate ok');
  is($info->{input_samplerate}, 48000, 'Input Sample Rate ok');
  is($info->{song_length_ms}, 496853, 'Song length ok');
  is($info->{audio_offset}, 100, 'Audio offset ok');
  is($info->{audio_size}, 230727, 'Audio size ok');
  is($info->{audio_md5}, '3c14a045e0e5b980b3e2a36a6ddae2de', 'Audio MD5 ok' );
  
  is($tags->{VENDOR}, 'KradRadio', 'vendor tag ok' );
}

{
  my $s = Audio::Scan->scan( _f('broken.testvector01.bit.opus'), { md5_size => 4096 } );

  my $info = $s->{info};
  my $tags = $s->{tags};
  
  is($info->{bitrate_average}, 163977, 'Bitrate ok');
  is($info->{channels}, 2, 'Channels ok');
  is($info->{file_size}, 472827, 'File size ok' );
  is($info->{stereo}, 1, 'Stereo ok');
  is($info->{samplerate}, 48000, 'Sample Rate ok');
  is($info->{input_samplerate}, 0, 'Input Sample Rate ok');
  is($info->{song_length_ms}, 23062, 'Song length ok');
  is($info->{audio_offset}, 122, 'Audio offset ok');
  is($info->{audio_size}, 472705, 'Audio size ok');
  is($info->{audio_md5}, 'c270fbb30987ba6fdccfc1e620bd4e4a', 'Audio MD5 ok' );
  
  is($tags->{VENDOR}, 'Encoded with GStreamer Opusenc', 'vendor tag ok' );
}

# XXX bug: no bitrate/length
{
  my $s = Audio::Scan->scan( _f('test-8-7.1.opus'), { md5_size => 4096 } );

  my $info = $s->{info};
  my $tags = $s->{tags};
  
  is($info->{bitrate_average}, undef, 'Bitrate ok');
  is($info->{channels}, 8, 'Channels ok');
  is($info->{file_size}, 543119, 'File size ok' );
  is($info->{stereo}, 0, 'Stereo ok');
  is($info->{samplerate}, 48000, 'Sample Rate ok');
  is($info->{input_samplerate}, 44100, 'Input Sample Rate ok');
  is($info->{song_length_ms}, undef, 'Song length ok');
  is($info->{audio_offset}, 157, 'Audio offset ok');
  is($info->{audio_size}, 542962, 'Audio size ok');
  is($info->{audio_md5}, 'cc3f80137c82c2be7e83ef5bd33fae1e', 'Audio MD5 ok' );

  is($tags->{VENDOR}, 'libopus 0.9.14', 'vendor tag ok' );
}

{
  my $s = Audio::Scan->scan( _f('tron.6ch.tinypkts.opus'), { md5_size => 4096 } );

  my $info = $s->{info};
  my $tags = $s->{tags};
  
  is($info->{bitrate_average}, 419457, 'Bitrate ok');
  is($info->{channels}, 6, 'Channels ok');
  is($info->{file_size}, 200704, 'File size ok' );
  is($info->{stereo}, 0, 'Stereo ok');
  is($info->{samplerate}, 48000, 'Sample Rate ok');
  is($info->{input_samplerate}, 48000, 'Input Sample Rate ok');
  is($info->{song_length_ms}, 3825, 'Song length ok');
  is($info->{audio_offset}, 151, 'Audio offset ok');
  is($info->{audio_size}, 200553, 'Audio size ok');
  is($info->{audio_md5}, '41942e1bf1b794cf3b2eac34f8f797cd', 'Audio MD5 ok' );
  
  is($tags->{VENDOR}, "opus-tools 0.1.0 (using libopus 0.9.10-83-g7143b2d)\n", 'vendor tag ok' );
}

sub _f {
    return catfile( $FindBin::Bin, 'opus', shift );
}
