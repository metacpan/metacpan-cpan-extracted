#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: $0 file1.sunvox file2.sunvox ..." unless @ARGV;

use Audio::SunVox::FFI ':all';

# Let's hope the default interface is a noise maker
sv_init;

my $slot = 0;
sv_open_slot( $slot );

for my $file ( @ARGV ) {
    sv_load( $slot, $file );
    sv_set_autostop( $slot, 1 );
    sv_play;
    printf "Now playing %s\n", sv_get_song_name( $slot );
    while ( ! sv_end_of_song( $slot ) ) {
        sleep( 1 );
    }
    sv_stop;
}

sv_close_slot( 0 );
sv_deinit;
