#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::StaticImageGallery' );
}

diag( "Testing App::StaticImageGallery $App::StaticImageGallery::VERSION, Perl $], $^X" );
