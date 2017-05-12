#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Apache::RandomImage' );
}

diag( "Testing Apache::RandomImage $Apache::RandomImage::VERSION, Perl $], $^X" );
