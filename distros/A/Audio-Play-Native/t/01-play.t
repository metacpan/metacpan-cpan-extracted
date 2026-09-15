#!/usr/bin/env perl

use 5.008001;
use strict;
use warnings;
use Test::More tests => 14;
use File::Temp qw(tempdir);
use Carp       qw(croak);

use lib 'lib';
use lib '../lib';
use lib 'Audio-Play-Native/lib';

use Audio::Play::Native;

# 1. Backend detection
my $backend = Audio::Play::Native->detected_backend;
ok( defined $backend, "detected backend: $backend" );
is(
    Audio::Play::Native->is_available,
    $backend ne 'none' ? 1 : 0,
    'is_available matches backend presence'
);

# 2. Procedural WAV generation
my $tmp_dir  = tempdir( CLEANUP => 1 );
my $tmp_ping = "$tmp_dir/test_ping.wav";
my $tmp_boom = "$tmp_dir/test_boom.wav";

ok(
    Audio::Play::Native->generate_demo_wav(
        $tmp_ping,
        type     => 'ping',
        duration => 0.1
    ),
    'generated ping wav'
);
ok( -f $tmp_ping,      'ping wav file exists' );
ok( -s $tmp_ping > 44, 'ping wav has non-trivial size' );

# Verify RIFF WAVE header bytes
open my $fh, '<:raw', $tmp_ping or croak $!;
my $riff_header = '';
read $fh, $riff_header, 12;
close $fh;
is( substr( $riff_header, 0, 4 ), 'RIFF', 'starts with RIFF magic bytes' );
is( substr( $riff_header, 8, 4 ), 'WAVE', 'format is WAVE' );

ok(
    Audio::Play::Native->generate_demo_wav(
        $tmp_boom,
        type     => 'explosion',
        duration => 0.1
    ),
    'generated explosion wav'
);
ok( -f $tmp_boom, 'explosion wav file exists' );

# 3. Input validation and error handling
my $eval_failed = !eval {
    Audio::Play::Native->play(undef);
    1;
};
ok( $eval_failed, 'croaks on undef filename' );

is( Audio::Play::Native->play('/nonexistent/path/to/sound.wav'),
    undef, 'returns undef for nonexistent file' );

# 4. Playback execution
my $test_wav = "$tmp_dir/quick.wav";
Audio::Play::Native->generate_demo_wav(
    $test_wav,
    type     => 'ping',
    duration => 0.05
);

SKIP: {
    skip 'No audio backend available on this system', 3
      unless Audio::Play::Native->is_available;

    # Synchronous
    my $sync_ok = eval {
        Audio::Play::Native->play( $test_wav, async => 0 );
        1;
    };
    ok( $sync_ok, 'synchronous playback lives' );

    # Asynchronous
    my $res;
    my $async_ok = eval {
        $res = Audio::Play::Native->play( $test_wav, async => 1 );
        1;
    };
    ok( $async_ok,    'asynchronous playback lives' );
    ok( defined $res, 'async play returns truthy/PID' );
}

1;
