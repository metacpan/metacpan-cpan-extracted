#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Alien::VideoLAN::LibVLC' ) || print "Bail out!
";
}

diag( "Testing Alien::VideoLAN::LibVLC $Alien::VideoLAN::LibVLC::VERSION, Perl $], $^X" );
