#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Logger::Pipe' ) || print "Bail out!
";
}

diag( "Testing Dancer::Logger::Pipe $Dancer::Logger::Pipe::VERSION, Perl $], $^X" );
