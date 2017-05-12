#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Session::Driver::dbic' ) || print "Bail out!
";
}

diag( "Testing CGI::Session::Driver::dbic $CGI::Session::Driver::dbic::VERSION, Perl $], $^X" );
