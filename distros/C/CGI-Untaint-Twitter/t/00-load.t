#!perl -T

use Test::Most tests => 2;

BEGIN {
    use_ok( 'CGI::Untaint::Twitter' ) || print "Bail out!
";
}

require_ok('CGI::Untaint::Twitter') || print 'Bail out!';

diag( "Testing CGI::Untaint::Twitter $CGI::Untaint::Twitter::VERSION, Perl $], $^X" );
