#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'App::Spoor' ) || print "Bail out!\n";
    use_ok( 'App::Spoor::AccessEntryParser' ) || print "Bail out!\n";
    use_ok( 'App::Spoor::LoginEntryParser' ) || print "Bail out!\n";
}

diag( "Testing App::Spoor $App::Spoor::VERSION, Perl $], $^X" );
