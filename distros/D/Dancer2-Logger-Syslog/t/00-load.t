#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer2::Logger::Syslog' ) || print "Bail out!
";
}

diag( "Testing Dancer2::Logger::Syslog $Dancer2::Logger::Syslog::VERSION, Perl $], $^X" );
