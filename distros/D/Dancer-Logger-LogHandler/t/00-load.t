use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Logger::LogHandler' ) || print "Bail out!";
}

diag( "Testing Dancer::Logger::LogHandler $Dancer::Logger::LogHandler::VERSION, Perl $], $^X" );
