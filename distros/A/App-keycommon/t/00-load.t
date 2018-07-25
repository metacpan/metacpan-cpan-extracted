#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::keycommon' ) || print "Bail out!\n";
}

diag( "Testing App::keycommon $App::keycommon::VERSION, Perl $], $^X" );
