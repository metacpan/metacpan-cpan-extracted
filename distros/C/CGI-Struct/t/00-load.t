#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Struct' ) || print "Bail out!
";
}

diag( "Testing CGI::Struct $CGI::Struct::VERSION, Perl $], $^X" );
