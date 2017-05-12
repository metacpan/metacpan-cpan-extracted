#!/usr/bin/perl

use lib qw(blib/lib blib/arch);
use Audio::Scan;
use Time::HiRes qw(sleep);

my $file = shift;

$ENV{AUDIO_SCAN_NO_ARTWORK} = 1;

for ( 1..50000 ) {
    my $s = Audio::Scan->scan($file);
    
    # Also test in no artwork mode
    #{
    #    local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
    #    $s = Audio::Scan->scan($file);
    #}
    
    # Test find_frame doesn't leak
    if ( $file =~ /\.m4a$/ ) {
        Audio::Scan->find_frame_return_info( $file, 10 );
    }
    else {
        Audio::Scan->find_frame( $file, 10 );
    }
    
    sleep 0.001;
}
