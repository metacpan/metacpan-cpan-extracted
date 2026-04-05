#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Chandra::Game::Tetris' ) || print "Bail out!\n";
}

diag( "Testing Chandra::Game::Tetris $Chandra::Game::Tetris::VERSION, Perl $], $^X" );
