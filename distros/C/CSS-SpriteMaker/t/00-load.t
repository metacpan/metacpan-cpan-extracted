#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CSS::SpriteMaker' ) || print "Bail out!\n";
}

diag( "Testing CSS::FileMaker $CSS::SpriteMaker::VERSION, Perl $], $^X" );
