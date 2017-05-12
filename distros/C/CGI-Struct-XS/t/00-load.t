#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CGI::Struct::XS' ) || print "Bail out!
";
}

diag( "Testing CGI::Struct::XS $CGI::Struct::XS::VERSION, Perl $], $^X" );
