#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Pod2Epub' );
}

diag( "Testing App::Pod2Epub $App::Pod2Epub::VERSION, Perl $], $^X" );
