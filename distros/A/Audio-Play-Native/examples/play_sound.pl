#!/usr/bin/env perl

use 5.008001;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(sleep);

use Audio::Play::Native;

print '=' x 60, "\n";
print "Audio::Play::Native - Sound Playback Test\n";
print '=' x 60, "\n";

my $backend   = Audio::Play::Native->detected_backend;
my $available = Audio::Play::Native->is_available;

print "Operating System : $^O\n";
print "Detected Backend : $backend\n";
print "Audio Available  : " . ( $available ? 'Yes' : 'No' ) . "\n";
print '-' x 60, "\n";

unless ($available) {
    warn "WARNING: No supported audio player found in PATH on this system.\n";
    exit 1;
}

my $file_to_play;

if ( @ARGV && defined $ARGV[0] && -f $ARGV[0] ) {
    $file_to_play = $ARGV[0];
    print "Playing user-specified audio file: $file_to_play\n";
    print "Playback mode: Synchronous (waiting for completion)...\n";
    Audio::Play::Native->play( $file_to_play, async => 0 );
}
else {
    # Generate and play demo sounds
    my $demo_dir = "$FindBin::Bin/demo_sounds";
    mkdir $demo_dir unless -d $demo_dir;

    my $ping_file = "$demo_dir/demo_ping.wav";
    my $boom_file = "$demo_dir/demo_explosion.wav";

    print "No audio file specified on command line.\n";
    print "Generating procedural test audio files...\n";
    Audio::Play::Native->generate_demo_wav(
        $ping_file,
        type     => 'ping',
        duration => 0.4
    );
    Audio::Play::Native->generate_demo_wav(
        $boom_file,
        type     => 'explosion',
        duration => 0.6
    );
    print "  Created: $ping_file\n";
    print "  Created: $boom_file\n";
    print '-' x 60, "\n";

    print "1. Playing radar ping (synchronous)...\n";
    Audio::Play::Native->play( $ping_file, async => 0 );

    sleep(0.3);    # brief pause

    print "2. Playing explosion sound (synchronous)...\n";
    Audio::Play::Native->play( $boom_file, async => 0 );

    sleep(0.3);

    print "3. Testing asynchronous overlapping playback...\n";
    Audio::Play::Native->play($ping_file);
    sleep(0.15);
    Audio::Play::Native->play($boom_file);
    sleep(0.8);    # allow async playback to complete

    print '-' x 60, "\n";
    print "To test with your own audio file, run:\n";
    print "    perl $FindBin::Script /path/to/your/sound.wav\n";
}

print '=' x 60, "\n";
print "Audio test completed successfully!\n";
print '=' x 60, "\n";
