#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::readbuffer' ) || print "Bail out!\n";
}

diag( "Testing App::readbuffer $App::readbuffer::VERSION, Perl $], $^X" );
