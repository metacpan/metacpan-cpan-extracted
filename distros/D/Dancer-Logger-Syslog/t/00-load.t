#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Logger::Syslog' ) || print "Bail out!
";
}

diag( "Testing Dancer::Logger::Syslog $Dancer::Logger::Syslog::VERSION, Perl $], $^X" );
