#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Logger::ColorConsole' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Logger::ColorConsole $Dancer::Logger::ColorConsole::VERSION, Perl $], $^X" );
