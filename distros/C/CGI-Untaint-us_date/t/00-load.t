#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Untaint::us_date' ) || print "Bail out!
";
}

diag( "Testing CGI::Untaint::us_date $CGI::Untaint::us_date::VERSION, Perl $], $^X" );
