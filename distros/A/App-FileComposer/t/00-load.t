#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::FileComposer' ) || print "Bail out!\n";
}

diag( "Testing App::FileComposer $App::FileComposer::VERSION, Perl $], $^X" );
